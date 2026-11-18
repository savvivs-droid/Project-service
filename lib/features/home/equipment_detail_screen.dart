import 'package:flutter/material.dart';

import '../../core/constants/equipment_icons.dart';
import '../../core/constants/equipment_status.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/fullscreen_photo_viewer.dart';
import '../../core/widgets/language_switcher.dart';
import '../../models/equipment.dart';

/// Карточка оборудования (только просмотр): фото, название, вид, код
/// стикера, дата установки, фото стикера. Открывается по тапу на
/// оборудование в карточке заявки — и у клиента, и у администратора.
class EquipmentDetailScreen extends StatefulWidget {
  const EquipmentDetailScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  int _photoIndex = 0;

  Equipment get _equipment => widget.equipment;

  Color get _statusColor => switch (_equipment.status) {
        EquipmentStatus.active => const Color(0xFF2F9E63),
        EquipmentStatus.inRepair => const Color(0xFF2F6FED),
        EquipmentStatus.decommissioned => const Color(0xFF6E7B93),
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final typeLabel = equipmentTypeLabel(context, _equipment.type);
    final hasModel = _equipment.model?.isNotEmpty == true;
    final photos = _equipment.photos;

    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: l10n.equipmentLabel),
        actions: const [LanguageSwitcher()],
      ),
      body: ListView(
        children: [
          if (photos.isEmpty)
            Container(
              height: 200,
              color: _statusColor.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: Icon(
                equipmentTypeIcon(_equipment.type),
                size: 96,
                color: _statusColor,
              ),
            )
          else
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (index) =>
                        setState(() => _photoIndex = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => openFullscreenPhoto(context, photos[index]),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < photos.length; i++)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _photoIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        hasModel ? _equipment.model! : typeLabel,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        _equipment.status.label(context),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _statusColor,
                      side: BorderSide.none,
                    ),
                  ],
                ),
                if (hasModel) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(equipmentTypeIcon(_equipment.type),
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(typeLabel, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ],
                if (_equipment.stickerCode?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(_equipment.stickerCode!,
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _equipment.installedAt == null
                          ? l10n.installedAtNotSet
                          : l10n.installedAtSet(
                              _formatDate(_equipment.installedAt!)),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (_equipment.stickerPhotoUrl != null) ...[
                  const SizedBox(height: 20),
                  Text(l10n.stickerPhotoSectionTitle,
                      style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => openFullscreenPhoto(
                        context, _equipment.stickerPhotoUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _equipment.stickerPhotoUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
