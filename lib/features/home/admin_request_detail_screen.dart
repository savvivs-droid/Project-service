import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
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
    final costs = await showDialog<_MarkDoneCosts>(
      context: context,
      builder: (context) => const _MarkDoneDialog(),
    );
    if (costs == null) return;

    await _runAction(() => _repository.markDone(
          requestId: _item.request.id,
          repairCost: costs.repairCost,
          partsCost: costs.partsCost,
        ));
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
        title: AppBrandAppBarTitle(
          subtitle: context.l10n.requestDetailTitle(shortId),
        ),
        actions: [
          const LanguageSwitcher(),
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
                    if (_item.equipmentRefs.isEmpty)
                      Text(context.l10n.notSpecified)
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final ref in _item.equipmentRefs)
                            Chip(label: Text(ref.label(context))),
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
            if (isClosed)
              Text(
                request.technicianComment?.isNotEmpty == true
                    ? request.technicianComment!
                    : context.l10n.notSpecified,
              )
            else ...[
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
            ],
            if (request.repairCost != null || request.partsCost != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CostColumn(
                          label: context.l10n.requestCostRepairLabel,
                          value: request.repairCost,
                        ),
                      ),
                      Expanded(
                        child: _CostColumn(
                          label: context.l10n.requestCostPartsLabel,
                          value: request.partsCost,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

class _CostColumn extends StatelessWidget {
  const _CostColumn({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          '${(value ?? 0).toStringAsFixed(2)} Kč',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _MarkDoneCosts {
  const _MarkDoneCosts({required this.repairCost, required this.partsCost});

  final double repairCost;
  final double partsCost;
}

class _MarkDoneDialog extends StatefulWidget {
  const _MarkDoneDialog();

  @override
  State<_MarkDoneDialog> createState() => _MarkDoneDialogState();
}

class _MarkDoneDialogState extends State<_MarkDoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repairController = TextEditingController();
  final _partsController = TextEditingController();

  @override
  void dispose() {
    _repairController.dispose();
    _partsController.dispose();
    super.dispose();
  }

  double? _parse(String value) => double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return context.l10n.markDoneCostRequired;
    if (_parse(text) == null) return context.l10n.markDoneCostInvalid;
    return null;
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _MarkDoneCosts(
        repairCost: _parse(_repairController.text)!,
        partsCost: _parse(_partsController.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.markDoneDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _repairController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.markDoneRepairCostLabel,
                suffixText: 'Kč',
              ),
              validator: _validate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _partsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.l10n.markDonePartsCostLabel,
                suffixText: 'Kč',
              ),
              validator: _validate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.markDoneDialogCancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(context.l10n.markDoneDialogConfirm),
        ),
      ],
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
