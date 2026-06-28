import 'dart:math' as math;

import '../ast.dart';
import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerAggregate(Map<String, CellFunction> registry) {
  registry['SUM'] = (args, ctx) {
    var total = 0.0;
    for (final value in ctx.numbersFrom(args)) {
      total += value;
    }
    return NumberValue(total);
  };

  registry['SUMSQ'] = (args, ctx) {
    var total = 0.0;
    for (final value in ctx.numbersFrom(args)) {
      total += value * value;
    }
    return NumberValue(total);
  };

  registry['PRODUCT'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args);
    if (numbers.isEmpty) return const NumberValue(0);
    return NumberValue(numbers.reduce((a, b) => a * b));
  };

  registry['MIN'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args);
    if (numbers.isEmpty) return const NumberValue(0);
    return NumberValue(numbers.reduce(math.min));
  };

  registry['MAX'] = (args, ctx) {
    final numbers = ctx.numbersFrom(args);
    if (numbers.isEmpty) return const NumberValue(0);
    return NumberValue(numbers.reduce(math.max));
  };

  registry['SUMPRODUCT'] = (args, ctx) {
    arity(args, 1);
    final areas = [for (final arg in args) ctx.resolveArea(arg)];
    final length = areas.first.cells.length;
    for (final area in areas) {
      if (area.cells.length != length) {
        throw const EvalException(ErrorValue(ErrorKind.value));
      }
    }
    var total = 0.0;
    for (var i = 0; i < length; i++) {
      var product = 1.0;
      for (final area in areas) {
        product *= _numeric(area.cells[i]);
      }
      total += product;
    }
    return NumberValue(total);
  };

  registry['SUMIF'] = (args, ctx) {
    arity(args, 2, 3);
    final range = ctx.resolveArea(args[0]).cells;
    final criterion = ctx.eval(args[1]);
    final sumCells = args.length == 3 ? ctx.resolveArea(args[2]).cells : range;
    var total = 0.0;
    final count = math.min(range.length, sumCells.length);
    for (var i = 0; i < count; i++) {
      if (matchesCriterion(range[i], criterion, ctx) && sumCells[i] is NumberValue) {
        total += (sumCells[i] as NumberValue).value;
      }
    }
    return NumberValue(total);
  };

  registry['COUNTIF'] = (args, ctx) {
    arity(args, 2, 2);
    final range = ctx.resolveArea(args[0]).cells;
    final criterion = ctx.eval(args[1]);
    var count = 0;
    for (final candidate in range) {
      if (matchesCriterion(candidate, criterion, ctx)) count++;
    }
    return NumberValue(count.toDouble());
  };

  registry['AVERAGEIF'] = (args, ctx) {
    arity(args, 2, 3);
    final range = ctx.resolveArea(args[0]).cells;
    final criterion = ctx.eval(args[1]);
    final valueCells = args.length == 3 ? ctx.resolveArea(args[2]).cells : range;
    var total = 0.0;
    var count = 0;
    final limit = math.min(range.length, valueCells.length);
    for (var i = 0; i < limit; i++) {
      if (matchesCriterion(range[i], criterion, ctx) && valueCells[i] is NumberValue) {
        total += (valueCells[i] as NumberValue).value;
        count++;
      }
    }
    if (count == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
    return NumberValue(total / count);
  };

  registry['SUMIFS'] = (args, ctx) {
    arity(args, 3);
    final sumCells = ctx.resolveArea(args[0]).cells;
    final matches = _multiCriteria(args.sublist(1), sumCells.length, ctx);
    var total = 0.0;
    for (final index in matches) {
      if (sumCells[index] is NumberValue) total += (sumCells[index] as NumberValue).value;
    }
    return NumberValue(total);
  };

  registry['AVERAGEIFS'] = (args, ctx) {
    arity(args, 3);
    final valueCells = ctx.resolveArea(args[0]).cells;
    final matches = _multiCriteria(args.sublist(1), valueCells.length, ctx);
    var total = 0.0;
    var count = 0;
    for (final index in matches) {
      if (valueCells[index] is NumberValue) {
        total += (valueCells[index] as NumberValue).value;
        count++;
      }
    }
    if (count == 0) throw const EvalException(ErrorValue(ErrorKind.divZero));
    return NumberValue(total / count);
  };

  registry['COUNTIFS'] = (args, ctx) {
    arity(args, 2);
    final first = ctx.resolveArea(args[0]).cells;
    final matches = _multiCriteria(args, first.length, ctx);
    return NumberValue(matches.length.toDouble());
  };

  registry['MAXIFS'] = (args, ctx) {
    arity(args, 3);
    final valueCells = ctx.resolveArea(args[0]).cells;
    final matches = _multiCriteria(args.sublist(1), valueCells.length, ctx);
    final numbers = [
      for (final index in matches)
        if (valueCells[index] is NumberValue) (valueCells[index] as NumberValue).value,
    ];
    if (numbers.isEmpty) return const NumberValue(0);
    return NumberValue(numbers.reduce(math.max));
  };

  registry['MINIFS'] = (args, ctx) {
    arity(args, 3);
    final valueCells = ctx.resolveArea(args[0]).cells;
    final matches = _multiCriteria(args.sublist(1), valueCells.length, ctx);
    final numbers = [
      for (final index in matches)
        if (valueCells[index] is NumberValue) (valueCells[index] as NumberValue).value,
    ];
    if (numbers.isEmpty) return const NumberValue(0);
    return NumberValue(numbers.reduce(math.min));
  };
}

List<int> _multiCriteria(List<Expr> pairs, int length, EvalContext ctx) {
  final ranges = <List<CellValue>>[];
  final criteria = <CellValue>[];
  for (var i = 0; i + 1 < pairs.length; i += 2) {
    ranges.add(ctx.resolveArea(pairs[i]).cells);
    criteria.add(ctx.eval(pairs[i + 1]));
  }
  final matches = <int>[];
  for (var index = 0; index < length; index++) {
    var ok = true;
    for (var r = 0; r < ranges.length; r++) {
      if (index >= ranges[r].length || !matchesCriterion(ranges[r][index], criteria[r], ctx)) {
        ok = false;
        break;
      }
    }
    if (ok) matches.add(index);
  }
  return matches;
}

double _numeric(CellValue value) {
  if (value is NumberValue) return value.value;
  if (value is BooleanValue) return value.value ? 1 : 0;
  if (value is ErrorValue) throw EvalException(value);
  return 0;
}
