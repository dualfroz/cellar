import '../dates.dart';
import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerDate(Map<String, CellFunction> registry) {
  registry['DATE'] = (args, ctx) {
    arity(args, 3, 3);
    return NumberValue(serialFromDate(intArg(args[0], ctx), intArg(args[1], ctx), intArg(args[2], ctx)));
  };

  registry['TODAY'] = (args, ctx) {
    arity(args, 0, 0);
    return NumberValue(todaySerial());
  };

  registry['NOW'] = (args, ctx) {
    arity(args, 0, 0);
    final now = DateTime.now();
    final dayFraction =
        (now.hour * 3600 + now.minute * 60 + now.second) / 86400.0;
    return NumberValue(todaySerial() + dayFraction);
  };

  registry['YEAR'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(dateFromSerial(numberArg(args[0], ctx)).year.toDouble());
  };

  registry['MONTH'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(dateFromSerial(numberArg(args[0], ctx)).month.toDouble());
  };

  registry['DAY'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(dateFromSerial(numberArg(args[0], ctx)).day.toDouble());
  };

  registry['WEEKDAY'] = (args, ctx) {
    arity(args, 1, 2);
    final mode = args.length > 1 ? intArg(args[1], ctx) : 1;
    return NumberValue(weekday(numberArg(args[0], ctx), mode: mode).toDouble());
  };

  registry['DATEDIF'] = (args, ctx) {
    arity(args, 3, 3);
    final start = numberArg(args[0], ctx);
    final end = numberArg(args[1], ctx);
    final unit = textArg(args[2], ctx);
    if (end < start) throw const EvalException(ErrorValue(ErrorKind.numError));
    try {
      return NumberValue(datedif(start, end, unit).toDouble());
    } on ArgumentError {
      throw const EvalException(ErrorValue(ErrorKind.value));
    }
  };

  registry['EDATE'] = (args, ctx) {
    arity(args, 2, 2);
    return NumberValue(edate(numberArg(args[0], ctx), intArg(args[1], ctx)));
  };

  registry['EOMONTH'] = (args, ctx) {
    arity(args, 2, 2);
    final shifted = edate(numberArg(args[0], ctx), intArg(args[1], ctx));
    final date = dateFromSerial(shifted);
    return NumberValue(serialFromDate(date.year, date.month, daysInMonth(date.year, date.month)));
  };

  registry['DAYS'] = (args, ctx) {
    arity(args, 2, 2);
    return NumberValue((numberArg(args[0], ctx) - numberArg(args[1], ctx)).floorToDouble());
  };
}
