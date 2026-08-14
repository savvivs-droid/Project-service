import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../models/request_list_item.dart';
import 'request_chat_screen.dart';

/// Просмотр своей заявки клиентом — только чтение (статус, оборудование,
/// описание, время визита, комментарий мастера). Менять заявку клиент
/// не может — это делает администратор, см. AdminRequestDetailScreen.
class ClientRequestDetailScreen extends StatelessWidget {
  const ClientRequestDetailScreen({super.key, required this.item});

  final RequestListItem item;

  @override
  Widget build(BuildContext context) {
    final request = item.request;
    final shortId = request.id.substring(0, 8).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.requestDetailTitle(shortId)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestChatScreen(
                    requestId: request.id,
                    title: item.establishmentName,
                    otherPartyName: context.l10n.technicianName,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble),
              tooltip: context.l10n.chatWithTechnician,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.equipmentLabels.isEmpty
                      ? context.l10n.requestFallbackTitle
                      : item.equipmentLabels.join(', '),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RequestChatScreen(
                  requestId: request.id,
                  title: item.establishmentName,
                  otherPartyName: context.l10n.technicianName,
                ),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(context.l10n.chatWithTechnician),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.descriptionLabel,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(request.description),
                ],
              ),
            ),
          ),
          if (request.scheduledAt != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.visitTimeLabel,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(_formatDateTime(request.scheduledAt!)),
                  ],
                ),
              ),
            ),
          ],
          if (request.technicianComment != null &&
              request.technicianComment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.technicianCommentTitle,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(request.technicianComment!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label(context),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: status.color,
      side: BorderSide.none,
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
