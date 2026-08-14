import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../models/request_list_item.dart';
import '../../services/service_request_repository.dart';
import 'request_chat_screen.dart';

class AdminRequestDetailScreen extends StatefulWidget {
  const AdminRequestDetailScreen({super.key, required this.item});

  final RequestListItem item;

  @override
  State<AdminRequestDetailScreen> createState() =>
      _AdminRequestDetailScreenState();
}

class _AdminRequestDetailScreenState extends State<AdminRequestDetailScreen> {
  final _repository = ServiceRequestRepository();
  late final TextEditingController _commentController;

  bool _isSaving = false;

  RequestListItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: _item.request.technicianComment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _item.request.scheduledAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _item.request.scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    await _runAction(() => _repository.assignSchedule(
          requestId: _item.request.id,
          scheduledAt: scheduledAt,
        ));
  }

  Future<void> _saveComment() async {
    await _runAction(() => _repository.saveTechnicianComment(
          requestId: _item.request.id,
          comment: _commentController.text.trim(),
        ));
  }

  Future<void> _markDone() async {
    await _runAction(() => _repository.markDone(requestId: _item.request.id));
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelRequestDialogTitle),
        content: Text(context.l10n.cancelRequestDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancelRequestDialogDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.cancelRequestButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAction(() => _repository.cancel(requestId: _item.request.id));
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveChangesError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _item.request;
    final shortId = request.id.substring(0, 8).toUpperCase();
    final isClosed = request.status == RequestStatus.done ||
        request.status == RequestStatus.cancelled;

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
                    title: _item.establishmentName,
                    otherPartyName: _item.clientName,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble),
              tooltip: context.l10n.chatWithClient,
            ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _item.establishmentName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.clientLabel,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(_item.clientName),
                    if (_item.clientPhone != null) Text(_item.clientPhone!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RequestChatScreen(
                    requestId: request.id,
                    title: _item.establishmentName,
                    otherPartyName: _item.clientName,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(context.l10n.chatWithClient),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.equipmentLabel,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    if (_item.equipmentLabels.isEmpty)
                      Text(context.l10n.notSpecified)
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in _item.equipmentLabels)
                            Chip(label: Text(label)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickSchedule,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                request.scheduledAt == null
                    ? context.l10n.assignTimeButton
                    : context.l10n
                        .changeTimeButton(_formatDateTime(request.scheduledAt!)),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.technicianCommentTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.technicianCommentHint,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _saveComment,
                child: Text(context.l10n.saveCommentButton),
              ),
            ),
            const SizedBox(height: 12),
            if (!isClosed) ...[
              FilledButton(
                onPressed: _markDone,
                child: Text(context.l10n.markDoneButton),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _cancel,
                child: Text(context.l10n.cancelRequestButton),
              ),
            ],
            if (_isSaving) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
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
