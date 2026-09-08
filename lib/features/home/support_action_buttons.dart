import 'package:flutter/material.dart';

import '../../core/constants/support_contact.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/utils/launch_helpers.dart';
import 'client_create_request_screen.dart';

/// Плавающие кнопки "позвонить" и "создать заявку" — были только на
/// ClientHomeScreen, но пропадали на любом вложенном экране просмотра
/// оборудования (категории, виды, список приборов), потому что те
/// открываются отдельным Navigator.push без своих FAB. Общий виджет,
/// чтобы кнопки были доступны с любого такого экрана без дублирования
/// логики звонка/создания заявки.
class SupportActionButtons extends StatelessWidget {
  const SupportActionButtons({
    super.key,
    required this.establishmentId,
    required this.clientId,
    this.onRequestCreated,
  });

  final String? establishmentId;
  final String clientId;

  /// Вызывается после успешного создания заявки — на ClientHomeScreen
  /// используется, чтобы переключиться на вкладку "Активные" и
  /// обновить список; на вложенных экранах просмотра оборудования не
  /// нужен (пользователь просто возвращается туда, откуда открывал
  /// форму).
  final VoidCallback? onRequestCreated;

  Future<void> _callSupport(BuildContext context) async {
    final opened = await launchPhoneCall(kSupportPhoneNumber);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.callError)),
      );
    }
  }

  Future<void> _openCreateRequest(BuildContext context) async {
    final id = establishmentId;
    if (id == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientCreateRequestScreen(
          establishmentId: id,
          clientId: clientId,
        ),
      ),
    );
    if (created == true) onRequestCreated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          // Несколько экземпляров этого виджета оказываются на разных
          // экранах стека навигации одновременно (во время перехода) —
          // без heroTag: null Flutter падает на дублирующемся теге.
          heroTag: null,
          // Явный CircleBorder — иначе Material 3 по умолчанию рисует
          // скруглённый квадрат ("сквиркл"), а не круг.
          shape: const CircleBorder(),
          onPressed: () => _callSupport(context),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          tooltip: context.l10n.callUsTooltip,
          child: const Icon(Icons.call),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: null,
          // Явный StadiumBorder — полностью скруглённая "таблетка"
          // вместо квадратных углов по умолчанию в Material 3.
          shape: const StadiumBorder(),
          onPressed: () => _openCreateRequest(context),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.build_outlined),
          label: Text(context.l10n.clientCreateRequestButton),
        ),
      ],
    );
  }
}
