import '../ast.dart';
import '../evaluator.dart';
import '../values.dart';
import 'helpers.dart';

void registerLookup(Map<String, CellFunction> registry) {
  registry['INDEX'] = (args, ctx) {
    arity(args, 2, 3);
    final area = ctx.resolveArea(args[0]);
    if (args.length == 2) {
      final index = intArg(args[1], ctx);
      if (index < 1 || index > area.cells.length) {
        throw const EvalException(ErrorValue(ErrorKind.ref));
      }
      return area.cells[index - 1];
    }
    final rowNum = intArg(args[1], ctx);
    final colNum = intArg(args[2], ctx);
    if (rowNum < 1 || rowNum > area.rows || colNum < 1 || colNum > area.cols) {
      throw const EvalException(ErrorValue(ErrorKind.ref));
    }
    return area.at(rowNum - 1, colNum - 1);
  };

  registry['MATCH'] = (args, ctx) {
    arity(args, 2, 3);
    final needle = ctx.eval(args[0]);
    final haystack = ctx.resolveArea(args[1]).cells;
    final matchType = args.length > 2 ? intArg(args[2], ctx) : 1;
    final position = _matchPosition(needle, haystack, matchType, ctx);
    if (position < 0) throw const EvalException(ErrorValue(ErrorKind.na));
    return NumberValue((position + 1).toDouble());
  };

  registry['VLOOKUP'] = (args, ctx) {
    arity(args, 3, 4);
    final key = ctx.eval(args[0]);
    final area = ctx.resolveArea(args[1]);
    final colIndex = intArg(args[2], ctx);
    final approximate = args.length < 4 || boolArg(args[3], ctx);
    if (colIndex < 1 || colIndex > area.cols) {
      throw const EvalException(ErrorValue(ErrorKind.ref));
    }
    final firstColumn = [for (var row = 0; row < area.rows; row++) area.at(row, 0)];
    final row = _matchPosition(key, firstColumn, approximate ? 1 : 0, ctx);
    if (row < 0) throw const EvalException(ErrorValue(ErrorKind.na));
    return area.at(row, colIndex - 1);
  };

  registry['HLOOKUP'] = (args, ctx) {
    arity(args, 3, 4);
    final key = ctx.eval(args[0]);
    final area = ctx.resolveArea(args[1]);
    final rowIndex = intArg(args[2], ctx);
    final approximate = args.length < 4 || boolArg(args[3], ctx);
    if (rowIndex < 1 || rowIndex > area.rows) {
      throw const EvalException(ErrorValue(ErrorKind.ref));
    }
    final firstRow = [for (var col = 0; col < area.cols; col++) area.at(0, col)];
    final col = _matchPosition(key, firstRow, approximate ? 1 : 0, ctx);
    if (col < 0) throw const EvalException(ErrorValue(ErrorKind.na));
    return area.at(rowIndex - 1, col);
  };

  registry['LOOKUP'] = (args, ctx) {
    arity(args, 2, 3);
    final key = ctx.eval(args[0]);
    final search = ctx.resolveArea(args[1]).cells;
    final result = args.length == 3 ? ctx.resolveArea(args[2]).cells : search;
    final position = _matchPosition(key, search, 1, ctx);
    if (position < 0 || position >= result.length) {
      throw const EvalException(ErrorValue(ErrorKind.na));
    }
    return result[position];
  };

  registry['CHOOSE'] = (args, ctx) {
    arity(args, 2);
    final index = intArg(args[0], ctx);
    if (index < 1 || index >= args.length) {
      throw const EvalException(ErrorValue(ErrorKind.value));
    }
    return ctx.eval(args[index]);
  };

  registry['ROWS'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(ctx.resolveArea(args[0]).rows.toDouble());
  };

  registry['COLUMNS'] = (args, ctx) {
    arity(args, 1, 1);
    return NumberValue(ctx.resolveArea(args[0]).cols.toDouble());
  };

  registry['ROW'] = (args, ctx) {
    arity(args, 1, 1);
    final node = args[0];
    if (node is RefNode) return NumberValue((node.address.row + 1).toDouble());
    if (node is RangeNode) return NumberValue((node.start.row + 1).toDouble());
    throw const EvalException(ErrorValue(ErrorKind.value));
  };

  registry['COLUMN'] = (args, ctx) {
    arity(args, 1, 1);
    final node = args[0];
    if (node is RefNode) return NumberValue((node.address.col + 1).toDouble());
    if (node is RangeNode) return NumberValue((node.start.col + 1).toDouble());
    throw const EvalException(ErrorValue(ErrorKind.value));
  };
}

int _matchPosition(CellValue needle, List<CellValue> haystack, int matchType, EvalContext ctx) {
  if (matchType == 0) {
    for (var i = 0; i < haystack.length; i++) {
      if (haystack[i] is! ErrorValue && ctx.compare(needle, haystack[i]) == 0) return i;
    }
    return -1;
  }
  if (matchType > 0) {
    var best = -1;
    for (var i = 0; i < haystack.length; i++) {
      if (haystack[i] is ErrorValue) continue;
      if (ctx.compare(haystack[i], needle) <= 0) {
        best = i;
      } else {
        break;
      }
    }
    return best;
  }
  var best = -1;
  for (var i = 0; i < haystack.length; i++) {
    if (haystack[i] is ErrorValue) continue;
    if (ctx.compare(haystack[i], needle) >= 0) {
      best = i;
    } else {
      break;
    }
  }
  return best;
}
