import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/launch_helpers.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/request_list_item.dart';
import '../../models/establishment.dart';
import '../../models/profile.dart';
import '../../services/auth_repository.dart';
import '../../services/establishment_repository.dart';
import '../../services/push_notification_service.dart';
import '../../services/request_message_repository.dart';
import '../../services/service_request_repository.dart';
import 'admin_request_detail_screen.dart';
import 'admin_stats_tab.dart';
import 'establishment_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabIndex = 0;

  // Id заявок с непрочитанными сообщениями в чате — общий для всех
  // вкладок, живой (Realtime), см.
  // RequestMessageRepository.watchUnreadRequestIds.
  final _messageRepository = RequestMessageRepository();
  Set<String> _unreadRequestIds = const {};
  StreamSubscription<Set<String>>? _unreadSubscription;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [
      l10n.adminHomeActiveTab,
      l10n.adminHomeDoneTab,
      l10n.adminHomeClientsTab,
      l10n.adminHomeStatsTab,
    ];

    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: titles[_tabIndex]),
        actions: [
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
          _RequestsTab(showActive: true, unreadRequestIds: _unreadRequestIds),
          _RequestsTab(showActive: false, unreadRequestIds: _unreadRequestIds),
          const _ClientsTab(),
          const AdminStatsTab(),
        ],
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
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: l10n.adminHomeClientsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.adminHomeStatsTab,
          ),
        ],
      ),
    );
  }
}

/// Показывает либо только активные заявки (новая/согласовано время),
/// либо только закрытые (выполнено/отменено) — в зависимости от
/// [showActive]. Это отдельные вкладки нижней навигации, а не секции
/// одного списка.
class _RequestsTab extends StatefulWidget {
  const _RequestsTab({required this.showActive, required this.unreadRequestIds});

  final bool showActive;
  final Set<String> unreadRequestIds;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _repository = ServiceRequestRepository();
  final _searchController = TextEditingController();
  late Future<List<RequestListItem>> _requestsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchAll();
    setState(() => _requestsFuture = future);
    await future;
  }

  Future<void> _openDetail(RequestListItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminRequestDetailScreen(item: item),
      ),
    );
    if (changed == true) _refresh();
  }

  // Поиск только по адресу заведения и телефону клиента, как и просили
  // — не по названию/описанию.
  bool _matchesQuery(RequestListItem item) {
    if (_query.isEmpty) return true;
    final address = item.establishmentAddress?.toLowerCase() ?? '';
    final phone = item.clientPhone?.toLowerCase() ?? '';
    return address.contains(_query) || phone.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.searchByAddressOrPhoneHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<RequestListItem>>(
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
                  .where(_matchesQuery)
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
                            _query.isNotEmpty
                                ? context.l10n.searchNoResults
                                : widget.showActive
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
                  itemBuilder: (context, index) => _RequestCard(
                    item: items[index],
                    hasUnread:
                        widget.unreadRequestIds.contains(items[index].request.id),
                    onTap: () => _openDetail(items[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.hasUnread,
    required this.onTap,
  });

  final RequestListItem item;
  final bool hasUnread;
  final VoidCallback onTap;

  Future<void> _openMaps(BuildContext context) async {
    final address = item.establishmentAddress;
    if (address == null) return;
    final opened = await launchMapsSearch(address);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mapsOpenError)),
      );
    }
  }

  Future<void> _call(BuildContext context) async {
    final phone = item.clientPhone;
    if (phone == null) return;
    final opened = await launchPhoneCall(phone);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.callError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final colorScheme = Theme.of(context).colorScheme;

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
                      item.establishmentName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: request.status.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          request.status.label(context),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      if (request.repairCost != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${request.repairCost!.toStringAsFixed(2)} Kč',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.clientName, style: Theme.of(context).textTheme.bodySmall),
              if (item.establishmentAddress != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _openMaps(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place_outlined, size: 15, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.establishmentAddress!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (item.clientPhone != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _call(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_outlined, size: 15, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            item.clientPhone!,
                            style: TextStyle(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                item.equipmentRefs.isEmpty
                    ? request.description
                    : '${item.equipmentRefs.map((e) => e.label(context)).join(', ')} — ${request.description}',
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

class _ClientsTab extends StatefulWidget {
  const _ClientsTab();

  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab> {
  final _repository = EstablishmentRepository();
  final _searchController = TextEditingController();
  late Future<List<Establishment>> _establishmentsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _establishmentsFuture = _repository.fetchAllForAdmin();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchAllForAdmin();
    setState(() => _establishmentsFuture = future);
    await future;
  }

  bool _matchesQuery(Establishment establishment) {
    if (_query.isEmpty) return true;
    final address = establishment.address?.toLowerCase() ?? '';
    final phone = establishment.contactPhone?.toLowerCase() ?? '';
    return address.contains(_query) || phone.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.l10n.searchByAddressOrPhoneHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Establishment>>(
            future: _establishmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.l10n.establishmentsLoadError(
                        snapshot.error.toString(),
                      ),
                    ),
                  ),
                );
              }

              final establishments =
                  (snapshot.data ?? const []).where(_matchesQuery).toList();

              if (establishments.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            _query.isNotEmpty
                                ? context.l10n.searchNoResults
                                : context.l10n.noEstablishments,
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
                  itemCount: establishments.length,
                  itemBuilder: (context, index) => _EstablishmentCard(
                    establishment: establishments[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EstablishmentDetailScreen(
                          establishment: establishments[index],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
  const _EstablishmentCard({required this.establishment, required this.onTap});

  final Establishment establishment;
  final VoidCallback onTap;

  Future<void> _call(BuildContext context) async {
    final phone = establishment.contactPhone;
    if (phone == null) return;
    final opened = await launchPhoneCall(phone);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.callError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      establishment.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (establishment.ico != null)
                    Chip(
                      label: Text('IČO ${establishment.ico}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (establishment.address != null) ...[
                const SizedBox(height: 4),
                Text(
                  establishment.address!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (establishment.contactPhone != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _call(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, size: 15, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            establishment.contactPhone!,
                            style: TextStyle(
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
