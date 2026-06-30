import 'evaluator.dart';
import 'functions/aggregate.dart';
import 'functions/date.dart';
import 'functions/financial.dart';
import 'functions/info.dart';
import 'functions/logical.dart';
import 'functions/lookup.dart';
import 'functions/math.dart';
import 'functions/stats.dart';
import 'functions/text.dart';

Map<String, CellFunction> buildFunctions() {
  final registry = <String, CellFunction>{};
  registerMath(registry);
  registerAggregate(registry);
  registerStats(registry);
  registerText(registry);
  registerLogical(registry);
  registerInfo(registry);
  registerLookup(registry);
  registerDate(registry);
  registerFinancial(registry);
  return registry;
}

List<String> functionNames() => (buildFunctions().keys.toList())..sort();
