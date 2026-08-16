import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';
import '../../models/establishment.dart';
import '../../models/profile.dart';
import '../../models/request_list_item.dart';
import '../../services/auth_repository.dart';
import '../../services/equipment_repository.dart';
import '../../services/establishment_repository.dart';
import '../../services/request_message_repository.dart';
import '../../services/service_request_repository.dart';
import 'client_add_establishment_screen.dart';
import 'client_create_request_screen.dart';
import 'client_equipment_category_screen.dart';
import 'client_profile_tab.dart';
import 'client_request_detail_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
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

  Future<void> _openCreateRequest() async {
    final establishmentId = _selectedEstablishmentId;
    if (establishmentId == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientCreateRequestScreen(
          establishmentId: establishmentId,
          clientId: widget.profile.id,
        ),
      ),
    );
    if (created == true) {
      setState(() {
        _tabIndex = 0;
        _refreshTick++;
      });
    }
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
              return PopupMenuButton<String?>(
                icon: const Icon(Icons.storefront_outlined),
                tooltip: l10n.establishmentSwitcherTooltip,
                onSelected: (value) {
                  if (value == null) {
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
                    value: null,
                    child: Text(l10n.establishmentSwitcherAddNew),
                  ),
                ],
              );
            },
          ),
          const LanguageSwitcher(),
          IconButton(
            onPressed: () => AuthRepository().signOut(),
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
          ),
          ClientProfileTab(profile: widget.profile),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRequest,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.build_outlined),
        label: Text(l10n.clientCreateRequestButton),
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
                  Expanded(
                    child: Text(
                      item.equipmentRefs.isEmpty
                          ? context.l10n.requestFallbackTitle
                          : item.equipmentRefs
                              .map((e) => e.label(context))
                              .join(', '),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: request.status.color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      request.status.label(context),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
  const _ClientEquipmentTab({super.key, required this.establishmentId});

  final String? establishmentId;

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

  void _openCategory(
    BuildContext context,
    EquipmentTypeKey? key,
    String title,
    IconData icon,
  ) {
    final establishmentId = widget.establishmentId;
    if (establishmentId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientEquipmentCategoryScreen(
          establishmentId: establishmentId,
          typeKey: key,
          title: title,
          icon: icon,
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
        int countFor(EquipmentTypeKey? key) => equipment
            .where((item) => equipmentTypeKeyFromStorage(item.type) == key)
            .length;
        final otherCount = countFor(null);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            // Фиксированный максимальный размер плитки вместо
            // фиксированного числа колонок — на широком экране (планшет)
            // плитки остаются компактными квадратами, а не растягиваются
            // на всю ширину.
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            // Все известные категории показываем всегда; "Другое" —
            // только если у заведения реально есть такое оборудование.
            itemCount: EquipmentTypeKey.values.length + (otherCount > 0 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < EquipmentTypeKey.values.length) {
                final key = EquipmentTypeKey.values[index];
                return _CategoryTile(
                  icon: key.icon,
                  label: key.label(context),
                  count: countFor(key),
                  onTap: () =>
                      _openCategory(context, key, key.label(context), key.icon),
                );
              }
              return _CategoryTile(
                icon: Icons.more_horiz,
                label: context.l10n.equipmentTypeOther,
                count: otherCount,
                onTap: () => _openCategory(
                  context,
                  null,
                  context.l10n.equipmentTypeOther,
                  Icons.more_horiz,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Иконка и подпись раскладываются по фиксированным зонам
            // (а не центрируются как единый блок), иначе у подписей
            // на одну и две строки центр иконки съезжает по вертикали
            // и иконки в соседних плитках оказываются не на одном
            // уровне.
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Icon(icon, size: 30, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
