import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../models/service_request.dart';
import '../../services/service_request_repository.dart';

enum _StatsPeriod { week, month, year, custom }

/// Вкладка "Статистика" у администратора: количество закрытых заявок,
/// доход (сумма стоимости ремонта) и расход (сумма стоимости запчастей)
/// за выбранный период.
class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  final _repository = ServiceRequestRepository();

  _StatsPeriod _period = _StatsPeriod.month;
  late DateTimeRange _range;
  late Future<List<ServiceRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _range = _rangeFor(_StatsPeriod.month);
    _requestsFuture = _load();
  }

  DateTimeRange _rangeFor(_StatsPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case _StatsPeriod.week:
        return DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today.add(const Duration(days: 1)),
        );
      case _StatsPeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today.add(const Duration(days: 1)),
        );
      case _StatsPeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: today.add(const Duration(days: 1)),
        );
      case _StatsPeriod.custom:
        return _range;
    }
  }

  Future<List<ServiceRequest>> _load() {
    return _repository.fetchClosedInRange(start: _range.start, end: _range.end);
  }

  Future<void> _selectPeriod(_StatsPeriod period) async {
    if (period == _StatsPeriod.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: _range,
      );
      if (picked == null) return;
      setState(() {
        _period = period;
        _range = DateTimeRange(
          start: picked.start,
          end: picked.end.add(const Duration(days: 1)),
        );
        _requestsFuture = _load();
      });
      return;
    }

    setState(() {
      _period = period;
      _range = _rangeFor(period);
      _requestsFuture = _load();
    });
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _requestsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.statsPeriodWeek),
                selected: _period == _StatsPeriod.week,
                onSelected: (_) => _selectPeriod(_StatsPeriod.week),
              ),
              ChoiceChip(
                label: Text(l10n.statsPeriodMonth),
                selected: _period == _StatsPeriod.month,
                onSelected: (_) => _selectPeriod(_StatsPeriod.month),
              ),
              ChoiceChip(
                label: Text(l10n.statsPeriodYear),
                selected: _period == _StatsPeriod.year,
                onSelected: (_) => _selectPeriod(_StatsPeriod.year),
              ),
              ChoiceChip(
                label: Text(l10n.statsPeriodCustom),
                selected: _period == _StatsPeriod.custom,
                onSelected: (_) => _selectPeriod(_StatsPeriod.custom),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<ServiceRequest>>(
            future: _requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(l10n.statsLoadError(snapshot.error.toString())),
                  ),
                );
              }

              final requests = snapshot.data ?? const [];
              final revenue = requests.fold<double>(
                0,
                (sum, r) => sum + (r.repairCost ?? 0),
              );
              final expenses = requests.fold<double>(
                0,
                (sum, r) => sum + (r.partsCost ?? 0),
              );
              final profit = revenue - expenses;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatCard(
                    icon: Icons.task_alt,
                    label: l10n.statsClosedCount,
                    value: '${requests.length}',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.trending_up,
                    label: l10n.statsRevenue,
                    value: '${revenue.toStringAsFixed(2)} Kč',
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.trending_down,
                    label: l10n.statsExpenses,
                    value: '${expenses.toStringAsFixed(2)} Kč',
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: l10n.statsProfit,
                    value: '${profit.toStringAsFixed(2)} Kč',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
