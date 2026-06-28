import 'dart:math' as math;

import 'address.dart';
import 'ast.dart';
import 'names.dart';
import 'sheet.dart';
import 'values.dart';
import 'workbook.dart';

typedef CellFunction = CellValue Function(List<Expr> args, EvalContext ctx);

class Area {
  final List<CellValue> cells;
  final int rows;
  final int cols;
  const Area(this.cells, this.rows, this.cols);

  CellValue at(int row, int col) => cells[row * cols + col];
}

class EvalContext {
  final Workbook workbook;
  final Sheet currentSheet;
  final Map<String, CellFunction> functions;

  EvalContext({
    required this.workbook,
    required this.currentSheet,
    required this.functions,
  });

  CellValue evaluateCell(Expr expr) {
    try {
      return eval(expr);
    } on EvalException catch (error) {
      return error.error;
    }
  }

  CellValue eval(Expr expr) {
    switch (expr) {
      case NumberLit(:final value):
        return NumberValue(value);
      case TextLit(:final value):
        return TextValue(value);
      case BoolLit(:final value):
        return BooleanValue(value);
      case ErrorLit(:final kind):
        throw EvalException(ErrorValue(kind));
      case NameNode(:final name):
        return _evalName(name);
      case RefNode(:final address, :final sheet):
        return cellValue(sheet, address);
      case RangeNode():
        throw const EvalException(ErrorValue(ErrorKind.value));
      case UnaryOp(:final op, :final operand):
        return _applyUnary(op, eval(operand));
      case BinaryOp(:final op, :final left, :final right):
        return _applyBinary(op, eval(left), eval(right));
      case FuncCall(:final name, :final args):
        final fn = functions[name.toUpperCase()];
        if (fn == null) throw const EvalException(ErrorValue(ErrorKind.name));
        return fn(args, this);
    }
  }

  CellValue _evalName(String name) {
    switch (workbook.resolveName(name)) {
      case CellName(:final sheet, :final address):
        return sheet.valueAt(address);
      case RangeName():
        throw const EvalException(ErrorValue(ErrorKind.value));
      case null:
        throw const EvalException(ErrorValue(ErrorKind.name));
    }
  }

  CellValue cellValue(String? sheetName, CellAddress address) {
    final sheet = workbook.sheetFor(sheetName, currentSheet);
    if (sheet == null) throw const EvalException(ErrorValue(ErrorKind.ref));
    return sheet.valueAt(address);
  }

  List<CellValue> rangeValues(String? sheetName, CellAddress start, CellAddress end) {
    final sheet = workbook.sheetFor(sheetName, currentSheet);
    if (sheet == null) throw const EvalException(ErrorValue(ErrorKind.ref));
    return [for (final address in expandRange(start, end)) sheet.valueAt(address)];
  }

  Area resolveArea(Expr arg) {
    switch (arg) {
      case RangeNode(:final start, :final end, :final sheet):
        return Area(
          rangeValues(sheet, start, end),
          rangeRowCount(start, end),
          rangeColCount(start, end),
        );
      case RefNode(:final address, :final sheet):
        return Area([cellValue(sheet, address)], 1, 1);
      case NameNode(:final name):
        switch (workbook.resolveName(name)) {
          case RangeName(:final sheet, :final start, :final end):
            return Area(
              [for (final address in expandRange(start, end)) sheet.valueAt(address)],
              rangeRowCount(start, end),
              rangeColCount(start, end),
            );
          case CellName(:final sheet, :final address):
            return Area([sheet.valueAt(address)], 1, 1);
          case null:
            throw const EvalException(ErrorValue(ErrorKind.name));
        }
      default:
        return Area([eval(arg)], 1, 1);
    }
  }

  List<CellValue> flatten(List<Expr> args) {
    final values = <CellValue>[];
    for (final arg in args) {
      values.addAll(resolveArea(arg).cells);
    }
    return values;
  }

  List<double> numbersFrom(List<Expr> args) {
    final numbers = <double>[];
    for (final value in flatten(args)) {
      switch (value) {
        case NumberValue(:final value):
          numbers.add(value);
        case ErrorValue():
          throw EvalException(value);
        default:
          break;
      }
    }
    return numbers;
  }

  double asNumber(CellValue value) {
    switch (value) {
      case NumberValue(value: final number):
        return number;
      case BooleanValue(value: final flag):
        return flag ? 1.0 : 0.0;
      case BlankValue():
        return 0.0;
      case TextValue(value: final text):
        final trimmed = text.trim();
        if (trimmed.isEmpty) return 0.0;
        final parsed = double.tryParse(trimmed);
        if (parsed == null) throw const EvalException(ErrorValue(ErrorKind.value));
        return parsed;
      case ErrorValue():
        throw EvalException(value);
    }
  }

  bool asBoolean(CellValue value) {
    switch (value) {
      case BooleanValue(value: final flag):
        return flag;
      case NumberValue(value: final number):
        return number != 0;
      case BlankValue():
        return false;
      case TextValue(value: final text):
        switch (text.trim().toUpperCase()) {
          case 'TRUE':
            return true;
          case 'FALSE':
            return false;
          default:
            throw const EvalException(ErrorValue(ErrorKind.value));
        }
      case ErrorValue():
        throw EvalException(value);
    }
  }

  String asText(CellValue value) {
    switch (value) {
      case TextValue(value: final text):
        return text;
      case NumberValue(value: final number):
        return formatNumber(number);
      case BooleanValue(value: final flag):
        return flag ? 'TRUE' : 'FALSE';
      case BlankValue():
        return '';
      case ErrorValue():
        throw EvalException(value);
    }
  }

  CellValue _applyUnary(String op, CellValue operand) {
    if (op == '-') return NumberValue(-asNumber(operand));
    return NumberValue(asNumber(operand));
  }

  CellValue _applyBinary(String op, CellValue left, CellValue right) {
    switch (op) {
      case '+':
        return NumberValue(asNumber(left) + asNumber(right));
      case '-':
        return NumberValue(asNumber(left) - asNumber(right));
      case '*':
        return NumberValue(asNumber(left) * asNumber(right));
      case '/':
        final divisor = asNumber(right);
        if (divisor == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
        return NumberValue(asNumber(left) / divisor);
      case '%':
        final divisor = asNumber(right);
        if (divisor == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
        return NumberValue(asNumber(left) % divisor);
      case '^':
        return NumberValue(math.pow(asNumber(left), asNumber(right)).toDouble());
      case '&':
        return TextValue(asText(left) + asText(right));
      case '=':
        return BooleanValue(compare(left, right) == 0);
      case '<>':
        return BooleanValue(compare(left, right) != 0);
      case '<':
        return BooleanValue(compare(left, right) < 0);
      case '<=':
        return BooleanValue(compare(left, right) <= 0);
      case '>':
        return BooleanValue(compare(left, right) > 0);
      case '>=':
        return BooleanValue(compare(left, right) >= 0);
      default:
        throw const EvalException(ErrorValue(ErrorKind.value));
    }
  }

  int compare(CellValue left, CellValue right) {
    if (left is ErrorValue) throw EvalException(left);
    if (right is ErrorValue) throw EvalException(right);
    final leftNumber = _numericOrNull(left);
    final rightNumber = _numericOrNull(right);
    if (leftNumber != null && rightNumber != null) {
      return leftNumber.compareTo(rightNumber);
    }
    return asText(left).toUpperCase().compareTo(asText(right).toUpperCase());
  }

  double? _numericOrNull(CellValue value) {
    switch (value) {
      case NumberValue(value: final number):
        return number;
      case BooleanValue(value: final flag):
        return flag ? 1.0 : 0.0;
      case BlankValue():
        return 0.0;
      case TextValue(value: final text):
        return double.tryParse(text.trim());
      case ErrorValue():
        return null;
    }
  }
}
