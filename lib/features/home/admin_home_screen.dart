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
import '../../services/service_request_repository.dart';
import 'admin_request_detail_screen.dart';
import 'establishment_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [
      l10n.adminHomeActiveTab,
      l10n.adminHomeDoneTab,
      l10n.adminHomeClientsTab,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandIcon(size: 22),
            const SizedBox(width: 10),
            Text(titles[_tabIndex]),
          ],
        ),
        actions: [
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
        children: const [
          _RequestsTab(showActive: true),
          _RequestsTab(showActive: false),
          _ClientsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: l10n.navActive,
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: l10n.navDone,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: l10n.adminHomeClientsTab,
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
  const _RequestsTab({required this.showActive});

  final bool showActive;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _repository = ServiceRequestRepository();
  late Future<List<RequestListItem>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchAll();
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
            itemBuilder: (context, index) => _RequestCard(
              item: items[index],
              onTap: () => _openDetail(items[index]),
            ),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item, required this.onTap});

  final RequestListItem item;
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
                  Expanded(
                    child: Text(
                      item.establishmentName,
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
                item.equipmentLabels.isEmpty
                    ? request.description
                    : '${item.equipmentLabels.join(', ')} — ${request.description}',
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
  late Future<List<Establishment>> _establishmentsFuture;

  @override
  void initState() {
    super.initState();
    _establishmentsFuture = _repository.fetchAllForAdmin();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchAllForAdmin();
    setState(() => _establishmentsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Establishment>>(
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

        final establishments = snapshot.data ?? const [];
        if (establishments.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(context.l10n.noEstablishments)),
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
    );
  }
}

class _EstablishmentCard extends StatelessWidget {
  const _EstablishmentCard({required this.establishment, required this.onTap});

  final Establishment establishment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 2),
                Text(
                  establishment.contactPhone!,
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

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month, $hour:$minute';
}
