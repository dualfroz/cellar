# cellar

A spreadsheet engine with a formula language, written in pure Dart (no Flutter).

## What it does

- A1/B2 addressed cell grid with letter columns (A, Z, AA, AB, ...).
- Cell values: number, text, boolean, error (`#DIV/0!`, `#REF!`, `#CYCLE!`, `#NAME?`, `#NUM!`, `#VALUE!`) and formula.
- Formula language: `=A1+B2*3`, parentheses, operators (`+ - * / ^ %`, comparisons, `&`), literals, cell references, ranges (`A1:C3`) and function calls. A hand-written lexer feeds a recursive descent parser that builds an AST.
- Around 38 built-in functions: SUM, PRODUCT, AVERAGE/AVG, MIN, MAX, COUNT, COUNTA, ABS, SQRT, POWER, MOD, ROUND, TRUNC, INT, SIGN, FLOOR, CEIL/CEILING, IF, AND, OR, NOT, TRUE, FALSE, IFERROR, ISERROR, ISBLANK, ISNUMBER, ISTEXT, CONCAT/CONCATENATE, LEN, LEFT, RIGHT, MID, UPPER, LOWER, TRIM, REPT, EXACT, VALUE, INDEX.
- Dependency graph: every formula records the cells it references; a change recomputes only the affected dependents (dirty propagation) in topological order (Kahn). Circular references resolve to `#CYCLE!` instead of looping.
- CSV import and export (RFC4180 quoting), for both computed values and raw formulas.

## Library

```dart
import 'package:cellar/cellar.dart';

final sheet = Sheet();
sheet.setValue('A1', '10');
sheet.setValue('A2', '20');
sheet.setValue('B1', '=SUM(A1:A2)');
print(sheet.valueOf('B1').display()); // 30
```

## CLI

```
dart run cellar <file.csv> [options]

  --set REF=CONTENT   Set a cell before printing (formula keeps its '=', e.g. --set B1==A1+1)
  --show REF          Print the value and raw content of a cell
  --formulas          Print the raw formulas grid
  --csv-values        Emit the computed sheet as CSV
  --csv-formulas      Emit the formulas sheet as CSV
```

Example:

```
dart run cellar example/invoice.csv
dart run cellar example/invoice.csv --set B2=10 --show D7
```

## Tests

```
dart analyze
dart test
```
