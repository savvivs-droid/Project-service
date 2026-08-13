import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/utils/launch_helpers.dart';
import '../../models/admin_request_list_item.dart';
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

  static const _titles = ['Все заявки', 'Клиенты'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tabIndex]),
        actions: [
          IconButton(
            onPressed: () => AuthRepository().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _RequestsTab(),
          _ClientsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Заявки',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Клиенты',
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final _repository = ServiceRequestRepository();
  late Future<List<AdminRequestListItem>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _repository.fetchAllForAdmin();
  }

  Future<void> _refresh() async {
    final future = _repository.fetchAllForAdmin();
    setState(() => _requestsFuture = future);
    await future;
  }

  Future<void> _openDetail(AdminRequestListItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminRequestDetailScreen(item: item),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminRequestListItem>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Не удалось загрузить заявки: ${snapshot.error}'),
            ),
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Заявок пока нет')),
                ),
              ],
            ),
          );
        }

        final active = items.where((item) => item.request.status.isActive).toList();
        final closed = items.where((item) => !item.request.status.isActive).toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty)
                _RequestsSection(
                  title: 'Активные заявки',
                  items: active,
                  onTap: _openDetail,
                ),
              if (closed.isNotEmpty)
                _RequestsSection(
                  title: 'Выполненные заявки',
                  items: closed,
                  onTap: _openDetail,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({
    required this.title,
    required this.items,
    required this.onTap,
  });

  final String title;
  final List<AdminRequestListItem> items;
  final ValueChanged<AdminRequestListItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '$title · ${items.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final item in items)
            _RequestCard(item: item, onTap: () => onTap(item)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item, required this.onTap});

  final AdminRequestListItem item;
  final VoidCallback onTap;

  Future<void> _openMaps(BuildContext context) async {
    final address = item.establishmentAddress;
    if (address == null) return;
    final opened = await launchMapsSearch(address);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть карты')),
      );
    }
  }

  Future<void> _call(BuildContext context) async {
    final phone = item.clientPhone;
    if (phone == null) return;
    final opened = await launchPhoneCall(phone);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось начать звонок')),
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
                      request.status.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(item.clientName, style: Theme.of(context).textTheme.bodySmall),
              if (item.establishmentAddress != null)
                InkWell(
                  onTap: () => _openMaps(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.place_outlined, size: 15, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.establishmentAddress!,
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
              if (item.clientPhone != null)
                InkWell(
                  onTap: () => _call(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
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
                  'Визит: ${_formatDateTime(request.scheduledAt!)}',
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
              child: Text('Не удалось загрузить заведения: ${snapshot.error}'),
            ),
          );
        }

        final establishments = snapshot.data ?? const [];
        if (establishments.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Заведений пока нет')),
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
