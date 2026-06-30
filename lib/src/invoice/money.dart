import 'dart:math' as math;

class Currency {
  final String code;
  final String symbol;
  final int decimals;
  final bool symbolBefore;

  const Currency(
    this.code, {
    this.symbol = '',
    this.decimals = 2,
    this.symbolBefore = false,
  });

  int get scale => math.pow(10, decimals).toInt();

  static const pln = Currency('PLN', symbol: 'zl', decimals: 2);
  static const eur = Currency('EUR', symbol: 'EUR', decimals: 2);
  static const usd = Currency('USD', symbol: r'$', decimals: 2, symbolBefore: true);
  static const gbp = Currency('GBP', symbol: 'GBP', decimals: 2, symbolBefore: true);

  static const _known = {'PLN': pln, 'EUR': eur, 'USD': usd, 'GBP': gbp};

  static Currency byCode(String code) =>
      _known[code.toUpperCase()] ?? Currency(code.toUpperCase());

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

class Money {
  final int minor;
  final Currency currency;

  const Money(this.minor, this.currency);

  factory Money.of(num amount, Currency currency) =>
      Money(_roundHalfUp(amount * currency.scale), currency);

  factory Money.parse(String text, Currency currency) {
    final parsed = double.parse(text.trim());
    return Money.of(parsed, currency);
  }

  static Money zero(Currency currency) => Money(0, currency);

  double get amount => minor / currency.scale;

  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(minor - other.minor, currency);
  }

  Money scaled(num factor) => Money(_roundHalfUp(minor * factor), currency);

  Money convertedTo(Currency target, double rate) =>
      Money.of(amount * rate, target);

  bool get isNegative => minor < 0;

  void _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Currency mismatch: ${currency.code} vs ${other.currency.code}');
    }
  }

  String formatPlain() {
    final negative = minor < 0;
    final digits = minor.abs().toString().padLeft(currency.decimals + 1, '0');
    final splitAt = digits.length - currency.decimals;
    final intPart = _group(digits.substring(0, splitAt));
    final fracPart = currency.decimals == 0 ? '' : '.${digits.substring(splitAt)}';
    return '${negative ? '-' : ''}$intPart$fracPart';
  }

  String format() {
    final body = formatPlain();
    if (currency.symbol.isEmpty) return '$body ${currency.code}';
    return currency.symbolBefore ? '${currency.symbol}$body' : '$body ${currency.symbol}';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => format();
}

int _roundHalfUp(num value) {
  if (value < 0) return -_roundHalfUp(-value);
  return (value + 0.5).floor();
}

String _group(String digits) {
  final buffer = StringBuffer();
  final length = digits.length;
  for (var i = 0; i < length; i++) {
    if (i > 0 && (length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
