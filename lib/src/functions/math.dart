import 'dart:math' as math;

import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

final math.Random _random = math.Random();

void registerMath(Map<String, CellFunction> registry) {
  registry['ABS'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(numberArg(args[0], ctx).abs());
  };

  registry['SQRT'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    if (value < 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(math.sqrt(value));
  };

  registry['POWER'] = (args, ctx) {
    arity(args, 2, 2);
    return NumberValue(math.pow(numberArg(args[0], ctx), numberArg(args[1], ctx)).toDouble());
  };

  registry['EXP'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(math.exp(numberArg(args[0], ctx)));
  };

  registry['LN'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    if (value <= 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(math.log(value));
  };

  registry['LOG10'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    if (value <= 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(math.log(value) / math.ln10);
  };

  registry['LOG'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final base = args.length > 1 ? numberArg(args[1], ctx) : 10.0;
    if (value <= 0 || base <= 0 || base == 1) {
      throw const EvalException(ErrorValue(ErrorKind.numError));
    }
    return NumberValue(math.log(value) / math.log(base));
  };

  registry['PI'] = (args, ctx) {
    arity(args, 0, 0);
    return const NumberValue(math.pi);
  };

  registry['MOD'] = (args, ctx) {
    arity(args, 2, 2);
    final divisor = numberArg(args[1], ctx);
    if (divisor == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
    final dividend = numberArg(args[0], ctx);
    return NumberValue(dividend - divisor * (dividend / divisor).floorToDouble());
  };

  registry['QUOTIENT'] = (args, ctx) {
    arity(args, 2, 2);
    final divisor = numberArg(args[1], ctx);
    if (divisor == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
    return NumberValue((numberArg(args[0], ctx) / divisor).truncateToDouble());
  };

  registry['ROUND'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final digits = args.length > 1 ? intArg(args[1], ctx) : 0;
    final factor = math.pow(10, digits).toDouble();
    return NumberValue((value * factor).roundToDouble() / factor);
  };

  registry['ROUNDUP'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final digits = args.length > 1 ? intArg(args[1], ctx) : 0;
    final factor = math.pow(10, digits).toDouble();
    final scaled = value * factor;
    final rounded = value >= 0 ? scaled.ceilToDouble() : scaled.floorToDouble();
    return NumberValue(rounded / factor);
  };

  registry['ROUNDDOWN'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final digits = args.length > 1 ? intArg(args[1], ctx) : 0;
    final factor = math.pow(10, digits).toDouble();
    return NumberValue((value * factor).truncateToDouble() / factor);
  };

  registry['MROUND'] = (args, ctx) {
    arity(args, 2, 2);
    final value = numberArg(args[0], ctx);
    final multiple = numberArg(args[1], ctx);
    if (multiple == 0) return const NumberValue(0);
    return NumberValue((value / multiple).roundToDouble() * multiple);
  };

  registry['TRUNC'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final digits = args.length > 1 ? intArg(args[1], ctx) : 0;
    final factor = math.pow(10, digits).toDouble();
    return NumberValue((value * factor).truncateToDouble() / factor);
  };

  registry['INT'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(numberArg(args[0], ctx).floorToDouble());
  };

  registry['SIGN'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    return NumberValue(value > 0 ? 1 : (value < 0 ? -1 : 0));
  };

  registry['EVEN'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    final magnitude = (value.abs() / 2).ceil() * 2;
    return NumberValue((value < 0 ? -magnitude : magnitude).toDouble());
  };

  registry['ODD'] = (args, ctx) {
    arity(args, 1, 1);
    final value = numberArg(args[0], ctx);
    var magnitude = value.abs().ceil();
    if (magnitude.isEven) magnitude += 1;
    return NumberValue((value < 0 ? -magnitude : magnitude).toDouble());
  };

  registry['FLOOR'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final significance = args.length > 1 ? numberArg(args[1], ctx) : 1.0;
    if (significance == 0) return const NumberValue(0);
    return NumberValue((value / significance).floorToDouble() * significance);
  };

  registry['CEIL'] = (args, ctx) {
    arity(args, 1, 2);
    final value = numberArg(args[0], ctx);
    final significance = args.length > 1 ? numberArg(args[1], ctx) : 1.0;
    if (significance == 0) return const NumberValue(0);
    return NumberValue((value / significance).ceilToDouble() * significance);
  };
  registry['CEILING'] = registry['CEIL']!;

  registry['GCD'] = (args, ctx) {
    arity(args, 1);
    var result = 0;
    for (final value in ctx.numbersFrom(args)) {
      result = _gcd(result, value.abs().floor());
    }
    return NumberValue(result.toDouble());
  };

  registry['LCM'] = (args, ctx) {
    arity(args, 1);
    var result = 1;
    for (final value in ctx.numbersFrom(args)) {
      final current = value.abs().floor();
      if (current == 0) return const NumberValue(0);
      result = result ~/ _gcd(result, current) * current;
    }
    return NumberValue(result.toDouble());
  };

  registry['FACT'] = (args, ctx) {
    arity(args, 1, 1);
    final n = intArg(args[0], ctx);
    if (n < 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    var product = 1.0;
    for (var i = 2; i <= n; i++) {
      product *= i;
    }
    return NumberValue(product);
  };

  registry['COMBIN'] = (args, ctx) {
    arity(args, 2, 2);
    final n = intArg(args[0], ctx);
    final k = intArg(args[1], ctx);
    if (k < 0 || n < 0 || k > n) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(_combin(n, k));
  };

  registry['SIN'] = _unaryMath(math.sin);
  registry['COS'] = _unaryMath(math.cos);
  registry['TAN'] = _unaryMath(math.tan);
  registry['ASIN'] = _unaryMath(math.asin);
  registry['ACOS'] = _unaryMath(math.acos);
  registry['ATAN'] = _unaryMath(math.atan);

  registry['ATAN2'] = (args, ctx) {
    arity(args, 2, 2);
    return NumberValue(math.atan2(numberArg(args[1], ctx), numberArg(args[0], ctx)));
  };

  registry['DEGREES'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(numberArg(args[0], ctx) * 180 / math.pi);
  };

  registry['RADIANS'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(numberArg(args[0], ctx) * math.pi / 180);
  };

  registry['RAND'] = (args, ctx) {
    arity(args, 0, 0);
    return NumberValue(_random.nextDouble());
  };

  registry['RANDBETWEEN'] = (args, ctx) {
    arity(args, 2, 2);
    final low = intArg(args[0], ctx);
    final high = intArg(args[1], ctx);
    if (high < low) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue((low + _random.nextInt(high - low + 1)).toDouble());
  };
}

CellFunction _unaryMath(double Function(double) fn) => (args, ctx) {
      arity(args, 1, 1);
      return NumberValue(fn(numberArg(args[0], ctx)));
    };

int _gcd(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x;
}

double _combin(int n, int k) {
  final limit = math.min(k, n - k);
  var result = 1.0;
  for (var i = 0; i < limit; i++) {
    result = result * (n - i) / (i + 1);
  }
  return result.roundToDouble();
}
