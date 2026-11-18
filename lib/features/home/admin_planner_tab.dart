import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/request_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../models/request_list_item.dart';
import '../../models/service_request.dart';
import '../../models/technician.dart';
import '../../services/service_request_repository.dart';
import '../../services/technician_repository.dart';
import 'admin_request_detail_screen.dart';
import 'assign_visit_sheet.dart';
import 'technicians_screen.dart';

/// Вкладка "Планировщик" у администратора: сетка на один день —
/// колонка на каждого техника, строки — часы с 8:00 до 22:00, визиты —
/// цветные блоки. Сверху — заявки, которым ещё не назначен техник.
/// Тап по пустой клетке — поставить заявку в этот час этому технику.
class AdminPlannerTab extends StatefulWidget {
  const AdminPlannerTab({super.key});

  @override
  State<AdminPlannerTab> createState() => AdminPlannerTabState();
}

class AdminPlannerTabState extends State<AdminPlannerTab> {
  static const _hourHeight = 60.0;
  static const _timeColumnWidth = 52.0;
  static const _minColumnWidth = 110.0;

  final _requestRepository = ServiceRequestRepository();
  final _technicianRepository = TechnicianRepository();

  late DateTime _day;
  List<Technician> _technicians = const [];
  List<RequestListItem> _visits = const [];
  List<RequestListItem> _unassigned = const [];
  bool _loading = true;
  bool _failed = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _day = _dateOnly(DateTime.now());
    reload();
    // Линия "сейчас" в сетке — сдвигаем раз в минуту.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _isToday) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool get _isToday => _day == _dateOnly(DateTime.now());

  /// Публичный — вызывается при переходе на вкладку, чтобы показать
  /// свежие данные (вкладки живут в IndexedStack и не пересоздаются).
  Future<void> reload() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await Future.wait([
        _technicianRepository.fetchAll(includeHidden: true),
        _requestRepository.fetchVisitsBetween(
          from: _day,
          to: _day.add(const Duration(days: 1)),
        ),
        _requestRepository.fetchUnassigned(),
      ]);
      if (!mounted) return;
      final allTechnicians = results[0] as List<Technician>;
      final visits = (results[1] as List<RequestListItem>)
          .where((item) => item.request.technicianId != null)
          .toList();
      final busyTechnicianIds =
          visits.map((item) => item.request.technicianId).toSet();
      setState(() {
        // Скрытый техник остаётся колонкой только в те дни, где у него
        // уже есть визиты — чтобы они не пропали из расписания.
        _technicians = allTechnicians
            .where((t) => t.isActive || busyTechnicianIds.contains(t.id))
            .toList();
        _visits = visits;
        _unassigned = results[2] as List<RequestListItem>;
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

  void _changeDay(DateTime day) {
    _day = _dateOnly(day);
    reload();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day.isBefore(firstDate)
          ? firstDate
          : (_day.isAfter(lastDate) ? lastDate : _day),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) _changeDay(picked);
  }

  Future<void> _openTechnicians() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TechniciansScreen()),
    );
    if (changed == true) reload();
  }

  Future<void> _openDetail(RequestListItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminRequestDetailScreen(item: item)),
    );
    if (changed == true) reload();
  }

  Future<void> _onEmptySlotTap(Technician technician, int hour) async {
    final l10n = context.l10n;
    if (_unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.plannerUnassignedEmpty)),
      );
      return;
    }

    final item = await showModalBottomSheet<RequestListItem>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${l10n.plannerPickRequestTitle}\n'
                  '${technician.name} · '
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final candidate in _unassigned)
                      ListTile(
                        title: Text(candidate.establishmentName),
                        subtitle: Text(
                          candidate.request.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(candidate),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (item == null || !mounted) return;

    final saved = await showAssignVisitSheet(
      context,
      item: item,
      technicianId: technician.id,
      date: _day,
      startHour: hour,
    );
    if (saved) reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        _DayBar(
          day: _day,
          isToday: _isToday,
          onPrevious: () => _changeDay(_day.subtract(const Duration(days: 1))),
          onNext: () => _changeDay(_day.add(const Duration(days: 1))),
          onPick: _pickDay,
          onToday: () => _changeDay(DateTime.now()),
          onTechnicians: _openTechnicians,
        ),
        if (_loading && _technicians.isEmpty && _visits.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_failed)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.plannerLoadError),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: reload,
                    child: Text(l10n.plannerRetry),
                  ),
                ],
              ),
            ),
          )
        else if (_technicians.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.plannerNoTechnicians, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openTechnicians,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(l10n.technicianAddButton),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          _UnassignedStrip(items: _unassigned, onTap: _openDetail),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildGrid()),
        ],
      ],
    );
  }

  Widget _buildGrid() {
    const hours = workdayEndHour - workdayStartHour;
    const gridHeight = hours * _hourHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = math.max(
          _minColumnWidth,
          (constraints.maxWidth - _timeColumnWidth) / _technicians.length,
        );
        final totalWidth = math.max(
          constraints.maxWidth,
          _timeColumnWidth + columnWidth * _technicians.length,
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: _timeColumnWidth),
                    for (final technician in _technicians)
                      SizedBox(
                        width: columnWidth,
                        child: _TechnicianHeader(technician: technician),
                      ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: reload,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: gridHeight,
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: _timeColumnWidth,
                                  child: _TimeColumn(hourHeight: _hourHeight),
                                ),
                                for (final technician in _technicians)
                                  SizedBox(
                                    width: columnWidth,
                                    child: _TechnicianColumn(
                                      technician: technician,
                                      visits: _visits
                                          .where((item) =>
                                              item.request.technicianId ==
                                              technician.id)
                                          .toList(),
                                      hourHeight: _hourHeight,
                                      onEmptySlotTap: (hour) =>
                                          _onEmptySlotTap(technician, hour),
                                      onVisitTap: _openDetail,
                                    ),
                                  ),
                              ],
                            ),
                            if (_isToday) _nowLine(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _nowLine() {
    final now = DateTime.now();
    final offset = (now.hour + now.minute / 60 - workdayStartHour) * _hourHeight;
    if (offset < 0 || offset > (workdayEndHour - workdayStartHour) * _hourHeight) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: offset,
      left: _timeColumnWidth - 4,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(child: Container(height: 1.5, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.onToday,
    required this.onTechnicians,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final VoidCallback onToday;
  final VoidCallback onTechnicians;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton(
              onPressed: onPick,
              child: Text(
                MaterialLocalizations.of(context).formatFullDate(day),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          if (!isToday)
            TextButton(onPressed: onToday, child: Text(l10n.plannerToday)),
          IconButton(
            onPressed: onTechnicians,
            icon: const Icon(Icons.engineering_outlined),
            tooltip: l10n.techniciansTitle,
          ),
        ],
      ),
    );
  }
}

class _UnassignedStrip extends StatelessWidget {
  const _UnassignedStrip({required this.items, required this.onTap});

  final List<RequestListItem> items;
  final ValueChanged<RequestListItem> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(l10n.plannerUnassignedEmpty, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Text(
            '${l10n.plannerUnassignedTitle} · ${items.length}',
            style: theme.textTheme.labelLarge,
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 200,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.secondary, width: 1.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onTap(item),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.establishmentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.request.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TechnicianHeader extends StatelessWidget {
  const _TechnicianHeader({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 6, backgroundColor: technician.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              technician.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.hourHeight});

  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      children: [
        for (var hour = workdayStartHour; hour < workdayEndHour; hour++)
          SizedBox(
            height: hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('${hour.toString().padLeft(2, '0')}:00', style: style),
              ),
            ),
          ),
      ],
    );
  }
}

class _TechnicianColumn extends StatelessWidget {
  const _TechnicianColumn({
    required this.technician,
    required this.visits,
    required this.hourHeight,
    required this.onEmptySlotTap,
    required this.onVisitTap,
  });

  final Technician technician;
  final List<RequestListItem> visits;
  final double hourHeight;
  final ValueChanged<int> onEmptySlotTap;
  final ValueChanged<RequestListItem> onVisitTap;

  bool _isBusy(int hour) {
    for (final item in visits) {
      final start = item.request.scheduledAt!.toLocal();
      final end = item.request.scheduledEnd!.toLocal();
      final slotStart = DateTime(start.year, start.month, start.day, hour);
      final slotEnd = slotStart.add(const Duration(hours: 1));
      if (start.isBefore(slotEnd) && slotStart.isBefore(end)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    const totalHours = workdayEndHour - workdayStartHour;

    return Stack(
      children: [
        Column(
          children: [
            for (var hour = workdayStartHour; hour < workdayEndHour; hour++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isBusy(hour) ? null : () => onEmptySlotTap(hour),
                child: Container(
                  height: hourHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: borderColor, width: 0.5),
                      left: BorderSide(color: borderColor, width: 0.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (final item in visits) _buildVisit(context, item, totalHours),
      ],
    );
  }

  Widget _buildVisit(BuildContext context, RequestListItem item, int totalHours) {
    final request = item.request;
    final start = request.scheduledAt!.toLocal();
    final duration = request.durationHours ?? ServiceRequest.defaultDurationHours;
    final startOffset = start.hour + start.minute / 60 - workdayStartHour;
    final top = (startOffset * hourHeight).clamp(0.0, totalHours * hourHeight);
    final bottom = ((startOffset + duration) * hourHeight)
        .clamp(0.0, totalHours * hourHeight);
    final height = bottom - top;
    if (height <= 0) return const SizedBox.shrink();

    final isDone = request.status == RequestStatus.done;
    final color = isDone
        ? technician.color.withValues(alpha: 0.45)
        : technician.color;
    const textColor = Colors.white;

    return Positioned(
      top: top + 1,
      left: 3,
      right: 3,
      height: height - 2,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onVisitTap(item),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isDone) ...[
                      const Icon(Icons.check, size: 12, color: textColor),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        formatVisitHours(start, duration),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    item.establishmentName,
                    maxLines: duration > 1 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (duration > 1 && item.establishmentAddress != null)
                  Flexible(
                    child: Text(
                      item.establishmentAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textColor, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
