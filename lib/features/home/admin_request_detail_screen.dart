import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/text_formatters.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/request_list_item.dart';
import '../../models/service_request.dart';
import '../../models/technician.dart';
import '../../services/service_request_repository.dart';
import '../../services/technician_repository.dart';
import 'assign_visit_sheet.dart';
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

  // Назначенный техник — для подписи в блоке "Визит техника".
  Technician? _technician;

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: _item.request.technicianComment ?? '');
    _loadTechnician();
  }

  Future<void> _loadTechnician() async {
    final technicianId = _item.request.technicianId;
    if (technicianId == null) return;
    try {
      final technicians =
          await TechnicianRepository().fetchAll(includeHidden: true);
      if (!mounted) return;
      setState(() {
        for (final technician in technicians) {
          if (technician.id == technicianId) _technician = technician;
        }
      });
    } catch (_) {
      // Подпись техника не критична — без неё карточка всё равно работает.
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Техник и время визита — общая форма с планировщиком. После
  /// назначения закрываем карточку с true, как и после других действий,
  /// чтобы список/планировщик перезагрузились.
  Future<void> _assignVisit() async {
    final saved = await showAssignVisitSheet(context, item: _item);
    if (saved && mounted) Navigator.of(context).pop(true);
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
            _VisitCard(
              request: request,
              technician: _technician,
              onAssign: isClosed ? null : _assignVisit,
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
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: const [CapitalizeFirstLetterFormatter()],
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

/// Блок "Визит техника": кто едет, когда и на сколько часов, и кнопка
/// назначить/изменить (для закрытых заявок — только просмотр).
class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.request,
    required this.technician,
    required this.onAssign,
  });

  final ServiceRequest request;
  final Technician? technician;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final start = request.scheduledAt?.toLocal();
    final duration =
        request.durationHours ?? ServiceRequest.defaultDurationHours;
    final isAssigned = start != null && request.technicianId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.visitSectionTitle, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            if (start == null)
              Text(l10n.visitNotAssigned)
            else ...[
              if (technician != null)
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: technician!.color),
                    const SizedBox(width: 8),
                    Text(technician!.name, style: theme.textTheme.titleSmall),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                '${MaterialLocalizations.of(context).formatMediumDate(start)}, '
                '${formatVisitHours(start, duration)}',
              ),
            ],
            if (onAssign != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  isAssigned ? l10n.visitChangeButton : l10n.visitAssignButton,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
