enum ErrorKind {
  divZero('#DIV/0!'),
  ref('#REF!'),
  cycle('#CYCLE!'),
  name('#NAME?'),
  value('#VALUE!'),
  numError('#NUM!'),
  parse('#ERROR!'),
  na('#N/A');

  final String symbol;
  const ErrorKind(this.symbol);

  static ErrorKind? fromSymbol(String symbol) {
    for (final kind in ErrorKind.values) {
      if (kind.symbol == symbol) return kind;
    }
    return null;
  }
}

sealed class CellValue {
  const CellValue();

  String display();
}

class NumberValue extends CellValue {
  final double value;
  const NumberValue(this.value);

  @override
  String display() => formatNumber(value);

  @override
  bool operator ==(Object other) => other is NumberValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'NumberValue(${display()})';
}

class TextValue extends CellValue {
  final String value;
  const TextValue(this.value);

  @override
  String display() => value;

  @override
  bool operator ==(Object other) => other is TextValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TextValue($value)';
}

class BooleanValue extends CellValue {
  final bool value;
  const BooleanValue(this.value);

  @override
  String display() => value ? 'TRUE' : 'FALSE';

  @override
  bool operator ==(Object other) => other is BooleanValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BooleanValue($value)';
}

class BlankValue extends CellValue {
  const BlankValue();

  @override
  String display() => '';

  @override
  bool operator ==(Object other) => other is BlankValue;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'BlankValue()';
}

class ErrorValue extends CellValue {
  final ErrorKind kind;
  const ErrorValue(this.kind);

  @override
  String display() => kind.symbol;

  @override
  bool operator ==(Object other) => other is ErrorValue && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'ErrorValue(${kind.symbol})';
}

class EvalException implements Exception {
  final ErrorValue error;
  const EvalException(this.error);

  ErrorKind get kind => error.kind;

  @override
  String toString() => 'EvalException(${error.kind.symbol})';
}

String formatNumber(double value) {
  if (value.isNaN) return ErrorKind.numError.symbol;
  if (value.isInfinite) return value.isNegative ? '-Infinity' : 'Infinity';
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  var text = value.toStringAsPrecision(12);
  if (text.contains('.') && !text.contains('e') && !text.contains('E')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
