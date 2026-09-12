import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/equipment_grid_tile.dart';
import '../../core/widgets/equipment_illustrations.dart';
import '../../core/widgets/fullscreen_photo_viewer.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../models/establishment.dart';
import '../../models/profile.dart';
import '../../models/request_list_item.dart';
import '../../services/auth_repository.dart';
import '../../services/equipment_repository.dart';
import '../../services/establishment_repository.dart';
import '../../services/push_notification_service.dart';
import '../../services/request_message_repository.dart';
import '../../services/service_request_repository.dart';
import 'client_add_establishment_screen.dart';
import 'client_equipment_category_screen.dart';
import 'client_equipment_types_screen.dart';
import 'client_profile_tab.dart';
import 'client_request_detail_screen.dart';
import 'support_action_buttons.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  // Не может совпасть с реальным id заведения (uuid) — используется как
  // значение пункта меню "добавить заведение" в переключателе, см. build().
  static const _addEstablishmentValue = '__add_establishment__';

  // Открываем сразу на "Моё оборудование" — это то, с чем клиент
  // взаимодействует чаще всего, а не список заявок.
  int _tabIndex = 2;

  // Меняется при каждой успешно созданной заявке или смене заведения,
  // чтобы пересоздать вкладки с новым ключом — иначе IndexedStack держит
  // их состояние и не подхватывает ни новую заявку, ни данные другого
  // заведения.
  int _refreshTick = 0;

  final _establishmentRepository = EstablishmentRepository();
  late Future<List<Establishment>> _establishmentsFuture;

  // Заведение "по умолчанию" из профиля — то, что заведено при
  // регистрации, — пока список остальных заведений клиента ещё не
  // загрузился (или клиент состоит только в одном).
  String? _selectedEstablishmentId;

  // Id заявок с непрочитанными сообщениями в чате — общий для всех
  // вкладок список, живой (обновляется через Realtime), см.
  // RequestMessageRepository.watchUnreadRequestIds.
  final _messageRepository = RequestMessageRepository();
  Set<String> _unreadRequestIds = const {};
  StreamSubscription<Set<String>>? _unreadSubscription;

  @override
  void initState() {
    super.initState();
    _selectedEstablishmentId = widget.profile.establishmentId;
    _establishmentsFuture = _loadEstablishments();
    _unreadSubscription = _messageRepository.watchUnreadRequestIds().listen(
      (ids) {
        if (mounted) setState(() => _unreadRequestIds = ids);
      },
    );
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  Future<List<Establishment>> _loadEstablishments() async {
    final list = await _establishmentRepository.fetchForCurrentClient();
    if (!mounted) return list;
    if (list.isNotEmpty &&
        !list.any((e) => e.id == _selectedEstablishmentId)) {
      setState(() => _selectedEstablishmentId = list.first.id);
    }
    return list;
  }

  void _selectEstablishment(String id) {
    if (id == _selectedEstablishmentId) return;
    setState(() {
      _selectedEstablishmentId = id;
      _refreshTick++;
    });
  }

  Future<void> _openAddEstablishment() async {
    final added = await Navigator.of(context).push<Establishment>(
      MaterialPageRoute(
        builder: (_) => const ClientAddEstablishmentScreen(),
      ),
    );
    if (added == null) return;
    setState(() {
      _selectedEstablishmentId = added.id;
      _refreshTick++;
      _establishmentsFuture = _loadEstablishments();
    });
  }

  void _onRequestCreatedFromFab() {
    setState(() {
      _tabIndex = 0;
      _refreshTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [
      l10n.adminHomeActiveTab,
      l10n.adminHomeDoneTab,
      l10n.clientEquipmentTab,
      l10n.profileTitle,
    ];

    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: titles[_tabIndex]),
        actions: [
          FutureBuilder<List<Establishment>>(
            future: _establishmentsFuture,
            builder: (context, snapshot) {
              final establishments = snapshot.data ?? const [];
              // PopupMenuButton считает выбор пункта с value: null тем же
              // самым, что и закрытие меню без выбора (Flutter вызывает
              // onCanceled, а не onSelected) — поэтому пункт "добавить
              // заведение" не мог использовать null как значение, иначе
              // нажатие на него ничего не делало. Используем сентинел.
              return PopupMenuButton<String>(
                icon: const Icon(Icons.storefront_outlined),
                tooltip: l10n.establishmentSwitcherTooltip,
                onSelected: (value) {
                  if (value == _addEstablishmentValue) {
                    _openAddEstablishment();
                  } else {
                    _selectEstablishment(value);
                  }
                },
                itemBuilder: (context) => [
                  for (final establishment in establishments)
                    CheckedPopupMenuItem(
                      value: establishment.id,
                      checked: establishment.id == _selectedEstablishmentId,
                      child: Text(establishment.name),
                    ),
                  if (establishments.isNotEmpty) const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _addEstablishmentValue,
                    child: Text(l10n.establishmentSwitcherAddNew),
                  ),
                ],
              );
            },
          ),
          const LanguageSwitcher(),
          IconButton(
            onPressed: () async {
              await PushNotificationService.instance.unregisterCurrentDevice();
              await AuthRepository().signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOutTooltip,
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _ClientRequestsTab(
            key: ValueKey('active-$_selectedEstablishmentId-$_refreshTick'),
            showActive: true,
            establishmentId: _selectedEstablishmentId,
            unreadRequestIds: _unreadRequestIds,
          ),
          _ClientRequestsTab(
            key: ValueKey('done-$_selectedEstablishmentId'),
            showActive: false,
            establishmentId: _selectedEstablishmentId,
            unreadRequestIds: _unreadRequestIds,
          ),
          _ClientEquipmentTab(
            key: ValueKey(_selectedEstablishmentId),
            establishmentId: _selectedEstablishmentId,
            clientId: widget.profile.id,
          ),
          ClientProfileTab(profile: widget.profile),
        ],
      ),
      floatingActionButton: SupportActionButtons(
        establishmentId: _selectedEstablishmentId,
        clientId: widget.profile.id,
        onRequestCreated: _onRequestCreatedFromFab,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadRequestIds.isNotEmpty,
              child: const Icon(Icons.assignment_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadRequestIds.isNotEmpty,
              child: const Icon(Icons.assignment),
            ),
            label: l10n.navActive,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadRequestIds.isNotEmpty,
              child: const Icon(Icons.task_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadRequestIds.isNotEmpty,
              child: const Icon(Icons.task_alt),
            ),
            label: l10n.navDone,
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen_outlined),
            selectedIcon: const Icon(Icons.kitchen),
            label: l10n.clientEquipmentTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profileTitle,
          ),
        ],
      ),
    );
  }
}

/// Заявки текущего клиента. Запрос тот же, что и на экране администратора
/// (ServiceRequestRepository.fetchAll()) — какие строки вернутся, решает
/// RLS в базе: клиенту видны только заявки заведений, где он состоит.
/// [establishmentId] дополнительно сужает список до одного выбранного в
/// переключателе заведения (см. _ClientHomeScreenState).
class _ClientRequestsTab extends StatefulWidget {
  const _ClientRequestsTab({
    super.key,
    required this.showActive,
    required this.establishmentId,
    required this.unreadRequestIds,
  });

  final bool showActive;
  final String? establishmentId;
  final Set<String> unreadRequestIds;

  @override
  State<_ClientRequestsTab> createState() => _ClientRequestsTabState();
}

class _ClientRequestsTabState extends State<_ClientRequestsTab> {
  final _repository = ServiceRequestRepository();
  late Future<List<RequestListItem>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetch();
  }

  Future<List<RequestListItem>> _fetch() {
    return _repository.fetchAll(establishmentId: widget.establishmentId);
  }

  Future<void> _refresh() async {
    final future = _fetch();
    setState(() => _requestsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RequestListItem>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.requestsLoadError(snapshot.error.toString()),
              ),
            ),
          );
        }

        final items = (snapshot.data ?? const [])
            .where((item) => item.request.status.isActive == widget.showActive)
            .toList();

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      widget.showActive
                          ? context.l10n.noActiveRequests
                          : context.l10n.noDoneRequests,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _ClientRequestCard(
              item: items[index],
              hasUnread: widget.unreadRequestIds.contains(items[index].request.id),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClientRequestDetailScreen(item: items[index]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientRequestCard extends StatelessWidget {
  const _ClientRequestCard({
    required this.item,
    required this.hasUnread,
    required this.onTap,
  });

  final RequestListItem item;
  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final refs = item.equipmentRefs;
    final primary = refs.isEmpty ? null : refs.first;
    final photoUrl = primary?.photoUrl;

    final nameText = primary == null
        ? context.l10n.requestFallbackTitle
        : refs.length > 1
            ? refs.map((e) => e.name(context)).join(', ')
            : primary.name(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: request.status.color, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoUrl == null)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: request.status.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        primary == null
                            ? Icons.build_outlined
                            : equipmentTypeIcon(primary.type),
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => openFullscreenPhoto(context, photoUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasUnread) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (primary != null)
                              Expanded(
                                child: Text(
                                  primary.label(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nameText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: request.status.color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                request.status.label(context),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (request.scheduledAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n
                      .visitLabel(_formatDateTime(request.scheduledAt!)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Категории оборудования заведения клиента — все известные типы
/// показываются всегда, даже если по ним пока ничего не заведено
/// (кроме "Другое", которое появляется только если такое оборудование
/// реально есть — свободный текст без известного типа). Нажатие на
/// плитку открывает список конкретных единиц этой категории. Добавляет
/// и меняет оборудование только администратор, см. EstablishmentDetailScreen.
class _ClientEquipmentTab extends StatefulWidget {
  const _ClientEquipmentTab({
    super.key,
    required this.establishmentId,
    required this.clientId,
  });

  final String? establishmentId;
  final String clientId;

  @override
  State<_ClientEquipmentTab> createState() => _ClientEquipmentTabState();
}

class _ClientEquipmentTabState extends State<_ClientEquipmentTab> {
  final _repository = EquipmentRepository();
  late Future<List<Equipment>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _equipmentFuture = _fetch();
  }

  Future<List<Equipment>> _fetch() {
    final establishmentId = widget.establishmentId;
    if (establishmentId == null) return Future.value(const []);
    return _repository.fetchForEstablishment(establishmentId);
  }

  Future<void> _refresh() async {
    final future = _fetch();
    setState(() => _equipmentFuture = future);
    await future;
  }

  void _openCategory(BuildContext context, EquipmentCategory category) {
    final establishmentId = widget.establishmentId;
    if (establishmentId == null) return;

    if (category == EquipmentCategory.other) {
      // "Другое" — без фиксированных видов, сразу список оборудования
      // со свободным типом.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientEquipmentCategoryScreen(
            establishmentId: establishmentId,
            clientId: widget.clientId,
            typeKey: null,
            title: category.label(context),
            icon: category.icon,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientEquipmentTypesScreen(
          establishmentId: establishmentId,
          clientId: widget.clientId,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Equipment>>(
      future: _equipmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.equipmentLoadError(snapshot.error.toString()),
              ),
            ),
          );
        }

        final equipment = snapshot.data ?? const [];
        int countFor(EquipmentCategory category) => equipment
            .where((item) =>
                (equipmentTypeKeyFromStorage(item.type)?.category ??
                    EquipmentCategory.other) ==
                category)
            .length;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemCount: EquipmentCategory.values.length,
            itemBuilder: (context, index) {
              final category = EquipmentCategory.values[index];
              return EquipmentGridTile(
                icon: category.icon,
                illustration: equipmentIllustrationFor(category),
                photoAsset: category.photoAsset,
                label: category.label(context),
                count: countFor(category),
                onTap: () => _openCategory(context, category),
              );
            },
          ),
        );
      },
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month, $hour:$minute';
}
