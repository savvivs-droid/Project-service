/// Проверка чешского IČO (8 цифр) по контрольной сумме.
///
/// Алгоритм: сумма первых 7 цифр с весами 8..2, остаток от деления на 11
/// определяет контрольную (8-ю) цифру. Ловит опечатки ещё до похода в ARES.
bool isValidCzechIco(String value) {
  final digitsOnly = value.trim();
  if (!RegExp(r'^\d{8}$').hasMatch(digitsOnly)) return false;

  final digits = digitsOnly.split('').map(int.parse).toList();
  var sum = 0;
  for (var i = 0; i < 7; i++) {
    sum += digits[i] * (8 - i);
  }

  final remainder = sum % 11;
  final expectedCheckDigit = switch (remainder) {
    0 => 1,
    1 => 0,
    _ => 11 - remainder,
  };

  return digits[7] == expectedCheckDigit;
}
