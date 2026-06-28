import 'address.dart';
import 'ast.dart';
import 'evaluator.dart';
import 'functions.dart';
import 'names.dart';
import 'parser.dart';
import 'sheet.dart';
import 'values.dart';

class Workbook {
  final Map<String, Sheet> _sheets = {};
  final Map<String, NameTarget> _names = {};
  final Map<String, CellFunction> _functions = buildFunctions();

  Workbook.empty();

  factory Workbook() => Workbook.empty();

  Iterable<Sheet> get sheets => _sheets.values;

  List<String> get sheetNames => _sheets.values.map((sheet) => sheet.name).toList();

  int get sheetCount => _sheets.length;

  Sheet? get firstSheet => _sheets.values.isEmpty ? null : _sheets.values.first;

  Sheet addSheet(String name) {
    if (sheetByName(name) != null) {
      throw ArgumentError('Sheet already exists: $name');
    }
    final sheet = Sheet.internal(name, this);
    _sheets[name] = sheet;
    return sheet;
  }

  Sheet sheet(String name) {
    final found = sheetByName(name);
    if (found == null) throw ArgumentError('No such sheet: $name');
    return found;
  }

  Sheet? sheetByName(String name) {
    final lower = name.toLowerCase();
    for (final sheet in _sheets.values) {
      if (sheet.name.toLowerCase() == lower) return sheet;
    }
    return null;
  }

  Sheet? sheetFor(String? name, Sheet owner) => name == null ? owner : sheetByName(name);

  void removeSheet(String name) {
    final target = sheet(name);
    _sheets.remove(target.name);
    _rebuildAllPrecedents();
    recalculate();
  }

  void defineName(String name, String reference, {Sheet? scope}) {
    final target = _targetFromExpr(parseFormula(reference), scope ?? firstSheet);
    if (target == null) throw ArgumentError('Not a reference: $reference');
    _names[name.toUpperCase()] = target;
    _rebuildAllPrecedents();
    recalculate();
  }

  void defineTarget(String name, NameTarget target) {
    _names[name.toUpperCase()] = target;
    _rebuildAllPrecedents();
    recalculate();
  }

  NameTarget? resolveName(String name) => _names[name.toUpperCase()];

  Iterable<MapEntry<String, NameTarget>> get definedNames => _names.entries;

  NameTarget? _targetFromExpr(Expr expr, Sheet? scope) {
    switch (expr) {
      case RefNode(:final address, :final sheet):
        final target = sheetFor(sheet, scope!);
        return target == null ? null : CellName(target, address);
      case RangeNode(:final start, :final end, :final sheet):
        final target = sheetFor(sheet, scope!);
        return target == null ? null : RangeName(target, start, end);
      default:
        return null;
    }
  }

  EvalContext contextFor(Sheet owner) =>
      EvalContext(workbook: this, currentSheet: owner, functions: _functions);

  void setCell(Sheet owner, CellAddress address, String input, {bool recalculate = true}) {
    final cell = owner.cells.putIfAbsent(address, Cell.new);
    final self = (owner, address);
    for (final precedent in cell.precedents) {
      precedent.$1.cells[precedent.$2]?.dependents.remove(self);
    }

    cell.raw = input;
    cell.formula = null;
    cell.precedents = <GlobalCell>{};

    if (input.startsWith('=')) {
      try {
        final ast = parseFormula(input.substring(1));
        cell.formula = ast;
        cell.precedents = _collectPrecedents(ast, owner);
        cell.value = const BlankValue();
      } on FormulaException {
        cell.value = const ErrorValue(ErrorKind.parse);
      } on FormatException {
        cell.value = const ErrorValue(ErrorKind.ref);
      }
    } else {
      cell.value = _literalValue(input);
    }

    for (final precedent in cell.precedents) {
      precedent.$1.cells.putIfAbsent(precedent.$2, Cell.new).dependents.add(self);
    }

    if (recalculate) _recompute(self);
  }

  void clearCell(Sheet owner, CellAddress address) {
    final cell = owner.cells[address];
    if (cell == null) return;
    final self = (owner, address);
    for (final precedent in cell.precedents) {
      precedent.$1.cells[precedent.$2]?.dependents.remove(self);
    }
    cell.raw = '';
    cell.formula = null;
    cell.precedents = <GlobalCell>{};
    cell.value = const BlankValue();
    _recompute(self);
  }

  void recalculate() {
    final all = _allCells();
    final ordering = _topoSort(all);
    for (final gc in ordering.unresolved) {
      gc.$1.cells[gc.$2]!.value = const ErrorValue(ErrorKind.cycle);
    }
    for (final gc in ordering.ordered) {
      _evaluate(gc);
    }
  }

  void _recompute(GlobalCell changed) {
    final dirty = _dependentsClosure(changed);
    final ordering = _topoSort(dirty);
    for (final gc in ordering.unresolved) {
      gc.$1.cells[gc.$2]!.value = const ErrorValue(ErrorKind.cycle);
    }
    for (final gc in ordering.ordered) {
      _evaluate(gc);
    }
  }

  void _evaluate(GlobalCell gc) {
    final cell = gc.$1.cells[gc.$2];
    if (cell == null) return;
    final formula = cell.formula;
    if (formula == null) return;
    cell.value = contextFor(gc.$1).evaluateCell(formula);
  }

  Set<GlobalCell> _allCells() {
    final all = <GlobalCell>{};
    for (final sheet in _sheets.values) {
      for (final address in sheet.cells.keys) {
        all.add((sheet, address));
      }
    }
    return all;
  }

  Set<GlobalCell> _dependentsClosure(GlobalCell root) {
    final visited = <GlobalCell>{};
    final stack = <GlobalCell>[root];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (!visited.add(current)) continue;
      final cell = current.$1.cells[current.$2];
      if (cell == null) continue;
      for (final dependent in cell.dependents) {
        if (!visited.contains(dependent)) stack.add(dependent);
      }
    }
    return visited;
  }

  _Ordering _topoSort(Set<GlobalCell> nodes) {
    final inDegree = <GlobalCell, int>{};
    for (final node in nodes) {
      final cell = node.$1.cells[node.$2];
      var degree = 0;
      if (cell != null) {
        for (final precedent in cell.precedents) {
          if (nodes.contains(precedent)) degree++;
        }
      }
      inDegree[node] = degree;
    }

    final queue = <GlobalCell>[
      for (final node in nodes)
        if (inDegree[node] == 0) node,
    ];
    final ordered = <GlobalCell>[];
    while (queue.isNotEmpty) {
      final node = queue.removeLast();
      ordered.add(node);
      final cell = node.$1.cells[node.$2];
      if (cell == null) continue;
      for (final dependent in cell.dependents) {
        if (!nodes.contains(dependent)) continue;
        final remaining = inDegree[dependent]! - 1;
        inDegree[dependent] = remaining;
        if (remaining == 0) queue.add(dependent);
      }
    }

    final orderedSet = ordered.toSet();
    final unresolved = <GlobalCell>{
      for (final node in nodes)
        if (!orderedSet.contains(node)) node,
    };
    return _Ordering(ordered, unresolved);
  }

  Set<GlobalCell> _collectPrecedents(Expr expr, Sheet owner) {
    final refs = <GlobalCell>{};
    void walk(Expr node) {
      switch (node) {
        case RefNode(:final address, :final sheet):
          final target = sheetFor(sheet, owner);
          if (target != null) refs.add((target, address));
        case RangeNode(:final start, :final end, :final sheet):
          final target = sheetFor(sheet, owner);
          if (target != null) {
            for (final address in expandRange(start, end)) {
              refs.add((target, address));
            }
          }
        case NameNode(:final name):
          switch (resolveName(name)) {
            case CellName(:final sheet, :final address):
              refs.add((sheet, address));
            case RangeName(:final sheet, :final start, :final end):
              for (final address in expandRange(start, end)) {
                refs.add((sheet, address));
              }
            case null:
              break;
          }
        case UnaryOp(:final operand):
          walk(operand);
        case BinaryOp(:final left, :final right):
          walk(left);
          walk(right);
        case FuncCall(:final args):
          for (final arg in args) {
            walk(arg);
          }
        case NumberLit():
        case TextLit():
        case BoolLit():
        case ErrorLit():
          break;
      }
    }

    walk(expr);
    return refs;
  }

  void _rebuildAllPrecedents() {
    for (final sheet in _sheets.values) {
      for (final cell in sheet.cells.values) {
        cell.dependents.clear();
      }
    }
    for (final sheet in _sheets.values) {
      for (final entry in sheet.cells.entries) {
        final formula = entry.value.formula;
        entry.value.precedents =
            formula == null ? <GlobalCell>{} : _collectPrecedents(formula, sheet);
      }
    }
    for (final sheet in _sheets.values) {
      for (final entry in sheet.cells.entries) {
        final self = (sheet, entry.key);
        for (final precedent in entry.value.precedents) {
          precedent.$1.cells.putIfAbsent(precedent.$2, Cell.new).dependents.add(self);
        }
      }
    }
  }

  CellValue _literalValue(String input) {
    if (input.isEmpty) return const BlankValue();
    final trimmed = input.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'TRUE') return const BooleanValue(true);
    if (upper == 'FALSE') return const BooleanValue(false);
    final number = double.tryParse(trimmed);
    if (number != null) return NumberValue(number);
    return TextValue(input);
  }
}

class _Ordering {
  final List<GlobalCell> ordered;
  final Set<GlobalCell> unresolved;
  const _Ordering(this.ordered, this.unresolved);
}
