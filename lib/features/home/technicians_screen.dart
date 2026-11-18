import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../models/technician.dart';
import '../../services/technician_repository.dart';

/// Список техников сервиса (администратор): добавить, переименовать,
/// сменить цвет, скрыть из планировщика. Возвращает true, если что-то
/// поменяли — тогда планировщик перезагружается.
class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  final _repository = TechnicianRepository();
  late Future<List<Technician>> _future;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchAll(includeHidden: true);
  }

  void _reload() {
    setState(() => _future = _repository.fetchAll(includeHidden: true));
  }

  Future<void> _edit({Technician? technician, required int count}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TechnicianDialog(
        technician: technician,
        // Новому технику — следующий цвет палитры, чтобы трое первых
        // сразу различались в планировщике.
        defaultColor: Technician.palette[count % Technician.palette.length],
        sortOrder: count,
      ),
    );
    if (saved == true) {
      _changed = true;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppBrandAppBarTitle(subtitle: l10n.techniciansTitle),
        ),
        body: FutureBuilder<List<Technician>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.plannerLoadError),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: Text(l10n.plannerRetry),
                    ),
                  ],
                ),
              );
            }
            final technicians = snapshot.data ?? const [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (technicians.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.techniciansEmpty)),
                  ),
                for (final technician in technicians)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: technician.isActive
                            ? technician.color
                            : technician.color.withValues(alpha: 0.3),
                        child: Text(
                          technician.name.characters.first.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(technician.name),
                      subtitle: Text(
                        [
                          if (technician.phone?.isNotEmpty == true)
                            technician.phone!,
                          if (!technician.isActive) l10n.technicianHidden,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(
                        technician: technician,
                        count: technicians.length,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _edit(count: technicians.length),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.technicianAddButton),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TechnicianDialog extends StatefulWidget {
  const _TechnicianDialog({
    required this.defaultColor,
    required this.sortOrder,
    this.technician,
  });

  final Technician? technician;
  final Color defaultColor;
  final int sortOrder;

  @override
  State<_TechnicianDialog> createState() => _TechnicianDialogState();
}

class _TechnicianDialogState extends State<_TechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = TechnicianRepository();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late Color _color;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final technician = widget.technician;
    _nameController = TextEditingController(text: technician?.name ?? '');
    _phoneController = TextEditingController(text: technician?.phone ?? '');
    _color = technician?.color ?? widget.defaultColor;
    _isActive = technician?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    try {
      final technician = widget.technician;
      if (technician == null) {
        await _repository.create(
          name: name,
          phone: phone.isEmpty ? null : phone,
          color: _color,
          sortOrder: widget.sortOrder,
        );
      } else {
        await _repository.update(
          id: technician.id,
          name: name,
          phone: phone.isEmpty ? null : phone,
          color: _color,
          isActive: _isActive,
        );
      }
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
    final selectedHex = Technician.colorToHex(_color);

    return AlertDialog(
      title: Text(
        widget.technician == null ? l10n.technicianAddButton : l10n.technicianLabel,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.technicianNameLabel),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? l10n.technicianNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration:
                    InputDecoration(labelText: l10n.technicianPhoneLabel),
              ),
              const SizedBox(height: 16),
              Text(l10n.technicianColorLabel,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in Technician.palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: color,
                        child: Technician.colorToHex(color) == selectedHex
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              if (widget.technician != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.technicianActiveLabel),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.technicianCancelButton),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.technicianSaveButton),
        ),
      ],
    );
  }
}
