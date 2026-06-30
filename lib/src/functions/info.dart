import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerInfo(Map<String, CellFunction> registry) {
  registry['ISERROR'] = _guarded((value) => value is ErrorValue);
  registry['ISERR'] = _guarded((value) => value is ErrorValue && value.kind != ErrorKind.na);
  registry['ISNA'] = _guarded((value) => value is ErrorValue && value.kind == ErrorKind.na);
  registry['ISNUMBER'] = _guarded((value) => value is NumberValue);
  registry['ISTEXT'] = _guarded((value) => value is TextValue);
  registry['ISLOGICAL'] = _guarded((value) => value is BooleanValue);
  registry['ISNONTEXT'] = _guarded((value) => value is! TextValue);

  registry['ISBLANK'] = (args, ctx) {
    arity(args, 1, 1);
    return BooleanValue(ctx.eval(args[0]) is BlankValue);
  };

  registry['NA'] = (args, ctx) {
    arity(args, 0, 0);
    throw const EvalException(ErrorValue(ErrorKind.na));
  };

  registry['N'] = (args, ctx) {
    arity(args, 1, 1);
    final value = ctx.eval(args[0]);
    switch (value) {
      case NumberValue(:final value):
        return NumberValue(value);
      case BooleanValue(:final value):
        return NumberValue(value ? 1 : 0);
      case ErrorValue():
        throw EvalException(value);
      default:
        return const NumberValue(0);
    }
  };

  registry['TYPE'] = (args, ctx) {
    arity(args, 1, 1);
    try {
      final value = ctx.eval(args[0]);
      return NumberValue(_typeCode(value).toDouble());
    } on EvalException {
      return const NumberValue(16);
    }
  };
}

int _typeCode(CellValue value) {
  switch (value) {
    case NumberValue():
    case BlankValue():
      return 1;
    case TextValue():
      return 2;
    case BooleanValue():
      return 4;
    case ErrorValue():
      return 16;
  }
}

CellFunction _guarded(bool Function(CellValue) predicate) => (args, ctx) {
      arity(args, 1, 1);
      try {
        return BooleanValue(predicate(ctx.eval(args[0])));
      } on EvalException catch (error) {
        return BooleanValue(predicate(error.error));
      }
    };
