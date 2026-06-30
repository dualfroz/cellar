import 'dart:math' as math;

import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerFinancial(Map<String, CellFunction> registry) {
  registry['PMT'] = (args, ctx) {
    arity(args, 3, 5);
    final rate = numberArg(args[0], ctx);
    final nper = numberArg(args[1], ctx);
    final pv = numberArg(args[2], ctx);
    final fv = args.length > 3 ? numberArg(args[3], ctx) : 0.0;
    final type = args.length > 4 ? numberArg(args[4], ctx) : 0.0;
    return NumberValue(_pmt(rate, nper, pv, fv, type));
  };

  registry['FV'] = (args, ctx) {
    arity(args, 3, 5);
    final rate = numberArg(args[0], ctx);
    final nper = numberArg(args[1], ctx);
    final pmt = numberArg(args[2], ctx);
    final pv = args.length > 3 ? numberArg(args[3], ctx) : 0.0;
    final type = args.length > 4 ? numberArg(args[4], ctx) : 0.0;
    if (rate == 0) return NumberValue(-(pv + pmt * nper));
    final growth = math.pow(1 + rate, nper).toDouble();
    return NumberValue(-(pv * growth + pmt * (1 + rate * type) * (growth - 1) / rate));
  };

  registry['PV'] = (args, ctx) {
    arity(args, 3, 5);
    final rate = numberArg(args[0], ctx);
    final nper = numberArg(args[1], ctx);
    final pmt = numberArg(args[2], ctx);
    final fv = args.length > 3 ? numberArg(args[3], ctx) : 0.0;
    final type = args.length > 4 ? numberArg(args[4], ctx) : 0.0;
    if (rate == 0) return NumberValue(-(fv + pmt * nper));
    final growth = math.pow(1 + rate, nper).toDouble();
    return NumberValue(-(fv + pmt * (1 + rate * type) * (growth - 1) / rate) / growth);
  };

  registry['NPER'] = (args, ctx) {
    arity(args, 3, 5);
    final rate = numberArg(args[0], ctx);
    final pmt = numberArg(args[1], ctx);
    final pv = numberArg(args[2], ctx);
    final fv = args.length > 3 ? numberArg(args[3], ctx) : 0.0;
    final type = args.length > 4 ? numberArg(args[4], ctx) : 0.0;
    if (rate == 0) {
      if (pmt == 0) throw const EvalException(ErrorValue(ErrorKind.numError));
      return NumberValue(-(pv + fv) / pmt);
    }
    final adjusted = pmt * (1 + rate * type);
    final numerator = adjusted - fv * rate;
    final denominator = pv * rate + adjusted;
    if (denominator == 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    final ratio = numerator / denominator;
    if (ratio <= 0) throw const EvalException(ErrorValue(ErrorKind.numError));
    return NumberValue(math.log(ratio) / math.log(1 + rate));
  };

  registry['RATE'] = (args, ctx) {
    arity(args, 3, 6);
    final nper = numberArg(args[0], ctx);
    final pmt = numberArg(args[1], ctx);
    final pv = numberArg(args[2], ctx);
    final fv = args.length > 3 ? numberArg(args[3], ctx) : 0.0;
    final type = args.length > 4 ? numberArg(args[4], ctx) : 0.0;
    final guess = args.length > 5 ? numberArg(args[5], ctx) : 0.1;
    return NumberValue(_rate(nper, pmt, pv, fv, type, guess));
  };

  registry['NPV'] = (args, ctx) {
    arity(args, 2);
    final rate = numberArg(args[0], ctx);
    final flows = ctx.numbersFrom(args.sublist(1));
    var total = 0.0;
    for (var i = 0; i < flows.length; i++) {
      total += flows[i] / math.pow(1 + rate, i + 1);
    }
    return NumberValue(total);
  };

  registry['IRR'] = (args, ctx) {
    arity(args, 1, 2);
    final flows = ctx.numbersFrom([args[0]]);
    final guess = args.length > 1 ? numberArg(args[1], ctx) : 0.1;
    return NumberValue(_irr(flows, guess));
  };
}

double _pmt(double rate, double nper, double pv, double fv, double type) {
  if (rate == 0) return -(pv + fv) / nper;
  final growth = math.pow(1 + rate, nper).toDouble();
  return -(pv * growth + fv) * rate / ((1 + rate * type) * (growth - 1));
}

double _npv(double rate, List<double> flows) {
  var total = 0.0;
  for (var i = 0; i < flows.length; i++) {
    total += flows[i] / math.pow(1 + rate, i);
  }
  return total;
}

double _irr(List<double> flows, double guess) {
  var low = -0.999999;
  var high = 10.0;
  var lowValue = _npv(low, flows);
  var highValue = _npv(high, flows);
  if (lowValue * highValue > 0) {
    var rate = guess;
    for (var i = 0; i < 100; i++) {
      final value = _npv(rate, flows);
      final derivative = (_npv(rate + 1e-6, flows) - value) / 1e-6;
      if (derivative == 0) break;
      final next = rate - value / derivative;
      if ((next - rate).abs() < 1e-9) return next;
      rate = next;
    }
    throw const EvalException(ErrorValue(ErrorKind.numError));
  }
  for (var i = 0; i < 200; i++) {
    final mid = (low + high) / 2;
    final midValue = _npv(mid, flows);
    if (midValue.abs() < 1e-9) return mid;
    if (lowValue * midValue < 0) {
      high = mid;
      highValue = midValue;
    } else {
      low = mid;
      lowValue = midValue;
    }
  }
  return (low + high) / 2;
}

double _rate(double nper, double pmt, double pv, double fv, double type, double guess) {
  var rate = guess;
  for (var i = 0; i < 100; i++) {
    final growth = math.pow(1 + rate, nper).toDouble();
    final value = pv * growth +
        pmt * (1 + rate * type) * (growth - 1) / (rate == 0 ? 1 : rate) +
        fv;
    final growthShift = math.pow(1 + rate + 1e-7, nper).toDouble();
    final shifted = pv * growthShift +
        pmt * (1 + (rate + 1e-7) * type) * (growthShift - 1) / (rate + 1e-7) +
        fv;
    final derivative = (shifted - value) / 1e-7;
    if (derivative == 0) break;
    final next = rate - value / derivative;
    if ((next - rate).abs() < 1e-9) return next;
    rate = next;
  }
  throw const EvalException(ErrorValue(ErrorKind.numError));
}
