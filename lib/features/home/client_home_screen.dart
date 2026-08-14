import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../models/profile.dart';
import '../../models/request_list_item.dart';
import '../../services/auth_repository.dart';
import '../../services/service_request_repository.dart';
import 'client_request_detail_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [l10n.adminHomeActiveTab, l10n.adminHomeDoneTab];

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
          _ClientRequestsTab(showActive: true),
          _ClientRequestsTab(showActive: false),
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
        ],
      ),
    );
  }
}

/// Заявки текущего клиента. Запрос тот же, что и на экране администратора
/// (ServiceRequestRepository.fetchAll()) — какие строки вернутся, решает
/// RLS в базе: клиенту видны только заявки его собственного заведения.
class _ClientRequestsTab extends StatefulWidget {
  const _ClientRequestsTab({required this.showActive});

  final bool showActive;

  @override
  State<_ClientRequestsTab> createState() => _ClientRequestsTabState();
}

class _ClientRequestsTabState extends State<_ClientRequestsTab> {
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
  const _ClientRequestCard({required this.item, required this.onTap});

  final RequestListItem item;
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
                  Expanded(
                    child: Text(
                      item.equipmentLabels.isEmpty
                          ? context.l10n.requestFallbackTitle
                          : item.equipmentLabels.join(', '),
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

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month, $hour:$minute';
}
