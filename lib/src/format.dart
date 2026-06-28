import 'values.dart';

enum FormatKind { general, number, percent, currency, scientific, integer }

class NumberFormat {
  final FormatKind kind;
  final int decimals;
  final bool thousands;
  final String currencySymbol;
  final bool symbolBefore;

  const NumberFormat({
    required this.kind,
    this.decimals = 2,
    this.thousands = false,
    this.currencySymbol = '',
    this.symbolBefore = true,
  });

  const NumberFormat.general() : this(kind: FormatKind.general);

  const NumberFormat.integer({bool thousands = false})
      : this(kind: FormatKind.integer, decimals: 0, thousands: thousands);

  const NumberFormat.decimal({int decimals = 2, bool thousands = false})
      : this(kind: FormatKind.number, decimals: decimals, thousands: thousands);

  const NumberFormat.percent({int decimals = 0})
      : this(kind: FormatKind.percent, decimals: decimals);

  const NumberFormat.currency(
    String symbol, {
    int decimals = 2,
    bool before = true,
    bool thousands = true,
  }) : this(
          kind: FormatKind.currency,
          decimals: decimals,
          thousands: thousands,
          currencySymbol: symbol,
          symbolBefore: before,
        );

  String apply(CellValue value) {
    if (value is! NumberValue) return value.display();
    final raw = value.value;
    switch (kind) {
      case FormatKind.general:
        return formatNumber(raw);
      case FormatKind.integer:
        return _fixed(raw, 0, thousands);
      case FormatKind.number:
        return _fixed(raw, decimals, thousands);
      case FormatKind.percent:
        return '${_fixed(raw * 100, decimals, false)}%';
      case FormatKind.currency:
        final body = _fixed(raw, decimals, thousands);
        return symbolBefore ? '$currencySymbol$body' : '$body$currencySymbol';
      case FormatKind.scientific:
        return raw.toStringAsExponential(decimals);
    }
  }

  String toCode() {
    switch (kind) {
      case FormatKind.general:
        return 'general';
      case FormatKind.integer:
        return thousands ? '#,##0' : '0';
      case FormatKind.number:
        return '${thousands ? '#,##0' : '0'}${_decimalSuffix()}';
      case FormatKind.percent:
        return '0${_decimalSuffix()}%';
      case FormatKind.currency:
        final body = '${thousands ? '#,##0' : '0'}${_decimalSuffix()}';
        return symbolBefore ? '$currencySymbol$body' : '$body$currencySymbol';
      case FormatKind.scientific:
        return '0${_decimalSuffix()}E+0';
    }
  }

  String _decimalSuffix() => decimals == 0 ? '' : '.${'0' * decimals}';

  static NumberFormat fromCode(String code) {
    if (code == 'general' || code.isEmpty) return const NumberFormat.general();
    if (code.endsWith('%')) {
      return NumberFormat.percent(decimals: _countDecimals(code));
    }
    if (code.contains('E+') || code.contains('e+')) {
      return NumberFormat(kind: FormatKind.scientific, decimals: _countDecimals(code));
    }
    final leading = _leadingSymbol(code);
    final trailing = _trailingSymbol(code);
    final thousands = code.contains(',');
    final decimals = _countDecimals(code);
    if (leading.isNotEmpty) {
      return NumberFormat.currency(leading, decimals: decimals, thousands: thousands);
    }
    if (trailing.isNotEmpty) {
      return NumberFormat.currency(trailing, decimals: decimals, before: false, thousands: thousands);
    }
    if (decimals == 0) return NumberFormat.integer(thousands: thousands);
    return NumberFormat.decimal(decimals: decimals, thousands: thousands);
  }

  static int _countDecimals(String code) {
    final dot = code.indexOf('.');
    if (dot < 0) return 0;
    var count = 0;
    for (var i = dot + 1; i < code.length; i++) {
      if (code[i] == '0' || code[i] == '#') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  static String _leadingSymbol(String code) {
    final buffer = StringBuffer();
    for (final rune in code.runes) {
      final ch = String.fromCharCode(rune);
      if ('0#,.'.contains(ch)) break;
      buffer.write(ch);
    }
    return buffer.toString();
  }

  static String _trailingSymbol(String code) {
    final buffer = StringBuffer();
    for (final rune in code.runes.toList().reversed) {
      final ch = String.fromCharCode(rune);
      if ('0#,.%'.contains(ch)) break;
      buffer.write(ch);
    }
    return String.fromCharCodes(buffer.toString().runes.toList().reversed);
  }

  @override
  bool operator ==(Object other) =>
      other is NumberFormat &&
      other.kind == kind &&
      other.decimals == decimals &&
      other.thousands == thousands &&
      other.currencySymbol == currencySymbol &&
      other.symbolBefore == symbolBefore;

  @override
  int get hashCode => Object.hash(kind, decimals, thousands, currencySymbol, symbolBefore);
}

String _fixed(double value, int decimals, bool thousands) {
  if (value.isNaN) return ErrorKind.numError.symbol;
  if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
  final negative = value < 0;
  final text = value.abs().toStringAsFixed(decimals);
  final dot = text.indexOf('.');
  final intPart = dot < 0 ? text : text.substring(0, dot);
  final fracPart = dot < 0 ? '' : text.substring(dot);
  final grouped = thousands ? _group(intPart) : intPart;
  return '${negative ? '-' : ''}$grouped$fracPart';
}

String _group(String digits) {
  final buffer = StringBuffer();
  final length = digits.length;
  for (var i = 0; i < length; i++) {
    if (i > 0 && (length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
