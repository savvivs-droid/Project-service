import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_brand.dart';
import '../../core/widgets/language_switcher.dart';

/// Заглушка — открывается по ссылке из галочки согласия на экране
/// регистрации. Реальный текст политики обработки персональных данных
/// нужно вставить сюда, когда он будет готов (юридически выверенный,
/// под юрисдикцию ЧР/ЕС — см. GDPR).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBrandAppBarTitle(subtitle: context.l10n.privacyPolicyTitle),
        actions: const [LanguageSwitcher()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(context.l10n.privacyPolicyPlaceholder),
        ),
      ),
    );
  }
}
