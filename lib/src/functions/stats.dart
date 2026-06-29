import 'dart:math' as math;

import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerStats(Map<String, CellFunction> registry) {
  registry['AVERAGE'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args);
    if (numbers.isEmpty) throw const EvalException(ErrorValue(ErrorKind.divZero));
    return NumberValue(numbers.reduce((a, b) => a + b) / numbers.length);
  };
  registry['AVG'] = registry['AVERAGE']!;

  registry['COUNT'] = (args, ctx) {
    var count = 0;
    for (final value in ctx.flatten(args)) {
      if (value is NumberValue) count++;
    }
    return NumberValue(count.toDouble());
  };

  registry['COUNTA'] = (args, ctx) {
    var count = 0;
    for (final value in ctx.flatten(args)) {
      if (value is! BlankValue) count++;
    }
    return NumberValue(count.toDouble());
  };

  registry['COUNTBLANK'] = (args, ctx) {
    var count = 0;
    for (final value in ctx.flatten(args)) {
      if (value is BlankValue) count++;
    }
    return NumberValue(count.toDouble());
  };

  registry['MEDIAN'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args)..sort();
    if (numbers.isEmpty) throw const EvalException(ErrorValue(ErrorKind.numError));
    final middle = numbers.length ~/ 2;
    if (numbers.length.isOdd) return NumberValue(numbers[middle]);
    return NumberValue((numbers[middle - 1] + numbers[middle]) / 2);
  };

  registry['MODE'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args);
    final counts = <double, int>{};
    for (final value in numbers) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    double? best;
    var bestCount = 1;
    for (final value in numbers) {
      final count = counts[value]!;
      if (count > bestCount) {
        bestCount = count;
        best = value;
      }
    }
    if (best == null) throw const EvalException(ErrorValue(ErrorKind.na));
    return NumberValue(best);
  };

  registry['VAR'] = (args, ctx) => NumberValue(_variance(ctx.numbersFrom(args), sample: true));
  registry['VARP'] = (args, ctx) => NumberValue(_variance(ctx.numbersFrom(args), sample: false));
  registry['STDEV'] = (args, ctx) =>
      NumberValue(math.sqrt(_variance(ctx.numbersFrom(args), sample: true)));
  registry['STDEVP'] = (args, ctx) =>
      NumberValue(math.sqrt(_variance(ctx.numbersFrom(args), sample: false)));

  registry['LARGE'] = (args, ctx) {
    arity(args, 2, 2);
    final numbers = ctx.numbersFrom([args[0]])..sort((a, b) => b.compareTo(a));
    final k = intArg(args[1], ctx);
    if (k < 1 || k > numbers.length) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(numbers[k - 1]);
  };

  registry['SMALL'] = (args, ctx) {
    arity(args, 2, 2);
    final numbers = ctx.numbersFrom([args[0]])..sort();
    final k = intArg(args[1], ctx);
    if (k < 1 || k > numbers.length) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(numbers[k - 1]);
  };

  registry['RANK'] = (args, ctx) {
    arity(args, 2, 3);
    final target = numberArg(args[0], ctx);
    final numbers = ctx.numbersFrom([args[1]]);
    final ascending = args.length > 2 && intArg(args[2], ctx) != 0;
    numbers.sort(ascending ? (a, b) => a.compareTo(b) : (a, b) => b.compareTo(a));
    final index = numbers.indexOf(target);
    if (index < 0) throw const EvalException(ErrorValue(ErrorKind.na));
    return NumberValue((index + 1).toDouble());
  };

  registry['PERCENTILE'] = (args, ctx) {
    arity(args, 2, 2);
    final numbers = ctx.numbersFrom([args[0]])..sort();
    if (numbers.isEmpty) throw const EvalException(ErrorValue(ErrorKind.numError));
    final fraction = numberArg(args[1], ctx);
    if (fraction < 0 || fraction > 1) throw const EvalException(ErrorValue(ErrorKind.numError));
    final position = fraction * (numbers.length - 1);
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return NumberValue(numbers[lower]);
    final weight = position - lower;
    return NumberValue(numbers[lower] * (1 - weight) + numbers[upper] * weight);
  };
}

double _variance(List<double> numbers, {required bool sample}) {
  final divisor = sample ? numbers.length - 1 : numbers.length;
  if (divisor <= 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
  final mean = numbers.reduce((a, b) => a + b) / numbers.length;
  var sum = 0.0;
  for (final value in numbers) {
    sum += (value - mean) * (value - mean);
  }
  return sum / divisor;
}
