import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../models/request_list_item.dart';
import '../../models/service_request.dart';
import '../../models/technician.dart';
import '../../services/service_request_repository.dart';
import '../../services/technician_repository.dart';

/// Рабочий день сервиса — без выходных, визиты начинаются в ровный
/// час с [workdayStartHour] и должны закончиться к [workdayEndHour].
const workdayStartHour = 8;
const workdayEndHour = 22;

/// Время визита в виде "10:00–12:00".
String formatVisitHours(DateTime start, int durationHours) {
  String hh(int hour) => '${hour.toString().padLeft(2, '0')}:00';
  final local = start.toLocal();
  return '${hh(local.hour)}–${hh(local.hour + durationHours)}';
}

/// Открывает форму назначения визита: техник, дата, час начала,
/// длительность. Сама сохраняет и возвращает true, если визит назначен.
/// [technicianId], [date], [startHour] — предзаполнение (например, тап по
/// пустой клетке планировщика); иначе берутся текущие значения заявки.
Future<bool> showAssignVisitSheet(
  BuildContext context, {
  required RequestListItem item,
  String? technicianId,
  DateTime? date,
  int? startHour,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AssignVisitSheet(
      item: item,
      initialTechnicianId: technicianId,
      initialDate: date,
      initialStartHour: startHour,
    ),
  );
  return saved == true;
}

class _AssignVisitSheet extends StatefulWidget {
  const _AssignVisitSheet({
    required this.item,
    this.initialTechnicianId,
    this.initialDate,
    this.initialStartHour,
  });

  final RequestListItem item;
  final String? initialTechnicianId;
  final DateTime? initialDate;
  final int? initialStartHour;

  @override
  State<_AssignVisitSheet> createState() => _AssignVisitSheetState();
}

class _AssignVisitSheetState extends State<_AssignVisitSheet> {
  final _technicianRepository = TechnicianRepository();
  final _requestRepository = ServiceRequestRepository();

  List<Technician>? _technicians;
  // Визиты всех техников на выбранную дату — для проверки пересечений.
  List<ServiceRequest> _dayVisits = const [];

  String? _technicianId;
  late DateTime _date;
  late int _startHour;
  late int _durationHours;

  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  ServiceRequest get _request => widget.item.request;

  @override
  void initState() {
    super.initState();
    final scheduled = _request.scheduledAt?.toLocal();
    final now = DateTime.now();

    _technicianId = widget.initialTechnicianId ?? _request.technicianId;

    final date = widget.initialDate ?? scheduled ?? now;
    _date = DateTime(date.year, date.month, date.day);

    int start = widget.initialStartHour ?? scheduled?.hour ?? now.hour + 1;
    if (start < workdayStartHour || start >= workdayEndHour) {
      start = workdayStartHour;
    }
    _startHour = start;

    _durationHours =
        _request.durationHours ?? ServiceRequest.defaultDurationHours;
    _clampDuration();

    _load();
  }

  int get _maxDuration => workdayEndHour - _startHour;

  void _clampDuration() {
    if (_durationHours > _maxDuration) _durationHours = _maxDuration;
    if (_durationHours < 1) _durationHours = 1;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final technicians =
          _technicians ?? await _technicianRepository.fetchAll();
      final visits = await _requestRepository.fetchVisitsBetween(
        from: _date,
        to: _date.add(const Duration(days: 1)),
      );
      if (!mounted) return;
      setState(() {
        _technicians = technicians;
        _dayVisits = visits.map((item) => item.request).toList();
        // Скрытый/удалённый техник или единственный техник — выбрать
        // осмысленное значение по умолчанию.
        if (!technicians.any((t) => t.id == _technicianId)) {
          _technicianId = technicians.length == 1 ? technicians.first.id : null;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _startHour);

  bool get _hasConflict {
    final technicianId = _technicianId;
    if (technicianId == null) return false;
    final start = _start;
    final end = start.add(Duration(hours: _durationHours));
    return _dayVisits.any((visit) {
      if (visit.id == _request.id || visit.technicianId != technicianId) {
        return false;
      }
      final otherStart = visit.scheduledAt!.toLocal();
      final otherEnd = visit.scheduledEnd!.toLocal();
      return start.isBefore(otherEnd) && otherStart.isBefore(end);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 365));
    // showDatePicker падает, если initialDate вне [firstDate, lastDate] —
    // а у старой заявки дата визита может быть в прошлом.
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate)
          ? firstDate
          : (_date.isAfter(lastDate) ? lastDate : _date),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null || !mounted) return;
    _date = DateTime(picked.year, picked.month, picked.day);
    await _load();
  }

  Future<void> _save() async {
    final technicianId = _technicianId;
    if (technicianId == null || _hasConflict) return;
    setState(() => _saving = true);
    try {
      await _requestRepository.assignVisit(
        requestId: _request.id,
        technicianId: technicianId,
        start: _start,
        durationHours: _durationHours,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveChangesError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final technicians = _technicians;

    Widget body;
    if (technicians == null && _loading) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (technicians == null || _failed) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(l10n.plannerLoadError),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(l10n.plannerRetry)),
          ],
        ),
      );
    } else if (technicians.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.visitNoTechnicians, textAlign: TextAlign.center),
      );
    } else {
      final canSave = _technicianId != null && !_hasConflict && !_loading;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.technicianLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final technician in technicians)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: technician.color),
                  label: Text(technician.name),
                  selected: technician.id == _technicianId,
                  onSelected: (_) =>
                      setState(() => _technicianId = technician.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.visitDateLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              MaterialLocalizations.of(context).formatFullDate(_date),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _startHour,
                  decoration: InputDecoration(labelText: l10n.visitStartLabel),
                  items: [
                    for (var hour = workdayStartHour;
                        hour < workdayEndHour;
                        hour++)
                      DropdownMenuItem(
                        value: hour,
                        child: Text('${hour.toString().padLeft(2, '0')}:00'),
                      ),
                  ],
                  onChanged: (hour) {
                    if (hour == null) return;
                    setState(() {
                      _startHour = hour;
                      _clampDuration();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  // key — чтобы список длительностей пересобрался, когда
                  // смена часа начала укоротила максимум.
                  key: ValueKey(_maxDuration),
                  initialValue: _durationHours,
                  decoration:
                      InputDecoration(labelText: l10n.visitDurationLabel),
                  items: [
                    for (var hours = 1; hours <= _maxDuration; hours++)
                      DropdownMenuItem(
                        value: hours,
                        child: Text(l10n.visitHoursShort(hours)),
                      ),
                  ],
                  onChanged: (hours) {
                    if (hours != null) setState(() => _durationHours = hours);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatVisitHours(_start, _durationHours),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (_hasConflict) ...[
            const SizedBox(height: 8),
            Text(
              l10n.visitConflict,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSave && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.visitSaveButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.technicianCancelButton),
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.item.establishmentName,
              style: theme.textTheme.titleMedium,
            ),
            if (widget.item.establishmentAddress != null)
              Text(
                widget.item.establishmentAddress!,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            body,
          ],
        ),
      ),
    );
  }
}
