import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerLogical(Map<String, CellFunction> registry) {
  registry['IF'] = (args, ctx) {
    arity(args, 2, 3);
    if (ctx.asBoolean(ctx.eval(args[0]))) return ctx.eval(args[1]);
    if (args.length == 3) return ctx.eval(args[2]);
    return const BooleanValue(false);
  };

  registry['IFS'] = (args, ctx) {
    arity(args, 2);
    if (args.length.isOdd) throw const EvalException(ErrorValue(ErrorKind.value));
    for (var i = 0; i < args.length; i += 2) {
      if (ctx.asBoolean(ctx.eval(args[i]))) return ctx.eval(args[i + 1]);
    }
    throw const EvalException(ErrorValue(ErrorKind.na));
  };

  registry['SWITCH'] = (args, ctx) {
    arity(args, 3);
    final subject = ctx.eval(args[0]);
    var i = 1;
    while (i + 1 < args.length) {
      if (ctx.compare(subject, ctx.eval(args[i])) == 0) return ctx.eval(args[i + 1]);
      i += 2;
    }
    if (i < args.length) return ctx.eval(args[i]);
    throw const EvalException(ErrorValue(ErrorKind.na));
  };

  registry['AND'] = (args, ctx) {
    arity(args, 1);
    var seen = false;
    var accumulated = true;
    for (final value in ctx.flatten(args)) {
      if (value is BlankValue) continue;
      accumulated = accumulated && ctx.asBoolean(value);
      seen = true;
    }
    if (!seen) throw const EvalException(ErrorValue(ErrorKind.value));
    return BooleanValue(accumulated);
  };

  registry['OR'] = (args, ctx) {
    arity(args, 1);
    var seen = false;
    var accumulated = false;
    for (final value in ctx.flatten(args)) {
      if (value is BlankValue) continue;
      accumulated = accumulated || ctx.asBoolean(value);
      seen = true;
    }
    if (!seen) throw const EvalException(ErrorValue(ErrorKind.value));
    return BooleanValue(accumulated);
  };

  registry['XOR'] = (args, ctx) {
    arity(args, 1);
    var trueCount = 0;
    var seen = false;
    for (final value in ctx.flatten(args)) {
      if (value is BlankValue) continue;
      if (ctx.asBoolean(value)) trueCount++;
      seen = true;
    }
    if (!seen) throw const EvalException(ErrorValue(ErrorKind.value));
    return BooleanValue(trueCount.isOdd);
  };

  registry['NOT'] = (args, ctx) {
    arity(args, 1, 1);
    return BooleanValue(!ctx.asBoolean(ctx.eval(args[0])));
  };

  registry['TRUE'] = (args, ctx) {
    arity(args, 0, 0);
    return const BooleanValue(true);
  };

  registry['FALSE'] = (args, ctx) {
    arity(args, 0, 0);
    return const BooleanValue(false);
  };

  registry['IFERROR'] = (args, ctx) {
    arity(args, 2, 2);
    try {
      final value = ctx.eval(args[0]);
      if (value is ErrorValue) return ctx.eval(args[1]);
      return value;
    } on EvalException {
      return ctx.eval(args[1]);
    }
  };

  registry['IFNA'] = (args, ctx) {
    arity(args, 2, 2);
    try {
      final value = ctx.eval(args[0]);
      if (value is ErrorValue && value.kind == ErrorKind.na) return ctx.eval(args[1]);
      return value;
    } on EvalException catch (error) {
      if (error.kind == ErrorKind.na) return ctx.eval(args[1]);
      rethrow;
    }
  };
}
