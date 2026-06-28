import '../ast.dart';
import '../evaluator.dart';
import '../values.dart';

void arity(List<Expr> args, int min, [int? max]) {
  final count = args.length;
  if (count < min || (max != null && count > max)) {
    throw const EvalException(ErrorValue(ErrorKind.value));
  }
}

double numberArg(Expr arg, EvalContext ctx) => ctx.asNumber(ctx.eval(arg));

String textArg(Expr arg, EvalContext ctx) => ctx.asText(ctx.eval(arg));

int intArg(Expr arg, EvalContext ctx) => numberArg(arg, ctx).truncate();

bool boolArg(Expr arg, EvalContext ctx) => ctx.asBoolean(ctx.eval(arg));

bool matchesCriterion(CellValue candidate, CellValue criterion, EvalContext ctx) {
  if (criterion is TextValue) {
    return _matchTextCriterion(candidate, criterion.value, ctx);
  }
  return _equalValues(candidate, criterion, ctx);
}

bool _matchTextCriterion(CellValue candidate, String spec, EvalContext ctx) {
  final trimmed = spec.trim();
  final operator = _leadingOperator(trimmed);
  if (operator != null) {
    final operand = trimmed.substring(operator.length).trim();
    return _compareWithOperator(candidate, operator, operand, ctx);
  }
  return _equalsText(candidate, trimmed, ctx);
}

String? _leadingOperator(String spec) {
  for (final op in const ['<>', '<=', '>=', '<', '>', '=']) {
    if (spec.startsWith(op)) return op;
  }
  return null;
}

bool _compareWithOperator(CellValue candidate, String op, String operand, EvalContext ctx) {
  final operandNumber = double.tryParse(operand);
  if (operandNumber != null && candidate is NumberValue) {
    final diff = candidate.value.compareTo(operandNumber);
    switch (op) {
      case '=':
        return diff == 0;
      case '<>':
        return diff != 0;
      case '<':
        return diff < 0;
      case '<=':
        return diff <= 0;
      case '>':
        return diff > 0;
      case '>=':
        return diff >= 0;
    }
  }
  final candidateText = _asPlainText(candidate, ctx);
  final compared = candidateText.toUpperCase().compareTo(operand.toUpperCase());
  switch (op) {
    case '=':
      return _wildcardEquals(candidateText, operand);
    case '<>':
      return !_wildcardEquals(candidateText, operand);
    case '<':
      return compared < 0;
    case '<=':
      return compared <= 0;
    case '>':
      return compared > 0;
    case '>=':
      return compared >= 0;
    default:
      return false;
  }
}

bool _equalsText(CellValue candidate, String operand, EvalContext ctx) {
  final operandNumber = double.tryParse(operand);
  if (operandNumber != null && candidate is NumberValue) {
    return candidate.value == operandNumber;
  }
  return _wildcardEquals(_asPlainText(candidate, ctx), operand);
}

bool _equalValues(CellValue candidate, CellValue criterion, EvalContext ctx) {
  if (candidate is NumberValue && criterion is NumberValue) {
    return candidate.value == criterion.value;
  }
  if (candidate is BooleanValue && criterion is BooleanValue) {
    return candidate.value == criterion.value;
  }
  return _asPlainText(candidate, ctx).toUpperCase() ==
      _asPlainText(criterion, ctx).toUpperCase();
}

String _asPlainText(CellValue value, EvalContext ctx) {
  if (value is BlankValue) return '';
  if (value is ErrorValue) return value.kind.symbol;
  return ctx.asText(value);
}

bool _wildcardEquals(String text, String pattern) {
  if (!pattern.contains('*') && !pattern.contains('?')) {
    return text.toUpperCase() == pattern.toUpperCase();
  }
  final buffer = StringBuffer('^');
  for (final rune in pattern.runes) {
    final ch = String.fromCharCode(rune);
    switch (ch) {
      case '*':
        buffer.write('.*');
      case '?':
        buffer.write('.');
      default:
        buffer.write(RegExp.escape(ch));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString(), caseSensitive: false).hasMatch(text);
}
