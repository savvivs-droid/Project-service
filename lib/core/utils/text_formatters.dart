import 'package:flutter/services.dart';

/// Делает заглавной только самую первую букву поля (не каждое слово и
/// не каждое предложение) — по одному этому символу и меняется длина
/// текста не бывает, поэтому позиция курсора остаётся корректной без
/// пересчёта. Работает независимо от платформы/раскладки клавиатуры,
/// в отличие от [TextCapitalization], который лишь подсказывает
/// виртуальной клавиатуре на мобильных и не трогает уже введённый текст.
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  const CapitalizeFirstLetterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final firstChar = text[0];
    final upper = firstChar.toUpperCase();
    if (firstChar == upper) return newValue;

    return newValue.copyWith(text: upper + text.substring(1));
  }
}
