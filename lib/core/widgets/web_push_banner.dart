import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/push_notification_service.dart';
import '../l10n/l10n_extension.dart';

const _dismissedKey = 'web_push_banner_dismissed';

/// Полоска над содержимым главного экрана в веб-версии: предлагает
/// включить push-уведомления (разрешение браузер спросит только по
/// нажатию кнопки), а на iPhone в Safari — сначала добавить приложение
/// на экран «Домой» (без этого iOS не даёт веб-push). На Android/iOS-
/// приложении не показывается — там уведомления через Firebase.
class WebPushBanner extends StatefulWidget {
  const WebPushBanner({super.key});

  @override
  State<WebPushBanner> createState() => _WebPushBannerState();
}

class _WebPushBannerState extends State<WebPushBanner> {
  String _status = 'unsupported';
  bool _dismissed = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _load();
  }

  Future<void> _load() async {
    final status = PushNotificationService.instance.webPushStatus;
    var dismissed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      dismissed = prefs.getBool(_dismissedKey) ?? false;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _status = status;
      _dismissed = dismissed;
    });
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedKey, true);
    } catch (_) {}
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    final ok = await PushNotificationService.instance.enableWebPush();
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() {
      _busy = false;
      _status = PushNotificationService.instance.webPushStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.webPushEnabled : l10n.webPushFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();
    if (_status != 'default' && _status != 'needs-install') {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final needsInstall = _status == 'needs-install';

    return Material(
      color: theme.colorScheme.secondary.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                needsInstall ? Icons.add_to_home_screen : Icons.notifications_active_outlined,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  needsInstall ? l10n.webPushInstallHint : l10n.webPushBannerText,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (!needsInstall) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _enable,
                  child: Text(l10n.webPushEnableButton),
                ),
              ],
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.webPushDismissTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
