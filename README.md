# cellar

cellar is a spreadsheet engine written in pure Dart, with no Flutter and no runtime dependencies.
It parses and evaluates spreadsheet formulas, keeps a dependency graph between cells so that an
edit recomputes only what depends on it, and detects circular references. On top of the engine it
offers multi-sheet workbooks with defined names, number formats, CSV and JSON storage, data tables
with grouping and pivots, and an invoice module with exact money arithmetic and text or HTML
output. Everything is usable as a library and through the `cellar` command line tool.

## Features

- **Cells and values.** A1-style addresses with letter columns (A ... Z, AA, AB, ...). A cell holds
  a number, text, boolean, blank, error or formula. Plain input is typed automatically: `TRUE` and
  `FALSE` become booleans, anything `double.parse` accepts becomes a number, the rest is text.
- **Formula language.** A hand-written lexer and a recursive descent parser build a sealed AST
  that an evaluator walks. Operators, literals, references, ranges, cross-sheet references,
  defined names and function calls are supported (see [Formula syntax](#formula-syntax)).
- **138 built-in functions** (141 names with aliases) in nine groups, listed in full in
  [Functions](#functions).
- **Dependency graph.** Every formula records its precedents, including cells on other sheets and
  cells behind defined names. Setting a cell re-links its edges, collects the transitive set of
  dependents and evaluates only that set in topological order (Kahn's algorithm). Cells left over
  by the sort, which are the members of a cycle and everything that depends on them, get
  `#CYCLE!`.
- **Errors.** `#DIV/0!`, `#REF!`, `#CYCLE!`, `#NAME?`, `#VALUE!`, `#NUM!`, `#N/A` and `#ERROR!`
  (formula that does not parse). Errors propagate through operators and functions and can be
  caught with `IFERROR`, `IFNA` and the `IS*` functions.
- **Workbooks.** Any number of named sheets (names are case-insensitive), references such as
  `Data!B2` or `'My Sheet'!A1:C3`, workbook-wide defined names pointing at a cell or a range, and
  sheet removal (references to a removed sheet become `#REF!`).
- **Number formats.** Per-cell display formats: general, integer, fixed decimals, thousands
  separators, percent, scientific and currency with the symbol before or after the number. Formats
  have a text code (`#,##0.00`, `0.0%`, `$#,##0.00`, `#,##0.00 zl`, `0.00E+0`) used by the JSON
  workbook format and by `TEXT()`.
- **CSV.** RFC 4180 parsing and writing (quoted fields, embedded commas, quotes and newlines).
  A sheet can be imported from CSV and exported either as computed values or as raw formulas, so a
  sheet with formulas survives a round trip.
- **JSON workbooks.** A versioned JSON document with sheets, raw cell contents, cell formats and
  defined names. Loading recalculates the whole workbook once.
- **Data tables.** A rectangular range of a sheet becomes a `DataTable` with a header row. Tables
  can be sorted by one or several columns, filtered, projected to a subset of columns, grouped with
  `sum`, `count`, `average`, `min`, `max` and `first` aggregations, and pivoted into a
  `PivotTable`.
- **Invoices.** Money is stored in integer minor units with half-up rounding. Built-in currencies
  are PLN, EUR, USD and GBP, any other ISO code works with a plain code suffix. Lines have quantity,
  unit, unit price, a discount rate and a VAT rate (23%, 8%, 5%, 0%, exempt `zw`, or any
  percentage). The invoice computes a VAT summary per rate (VAT is computed on the summed net of
  each rate), net, VAT and gross totals, and an optional total converted to a reporting currency.
  Numbering sequences use patterns such as `FV/{seq:04}/{year}`. Invoices load from and save to
  JSON and render as plain text or as a standalone HTML page with escaped content.
- **Command line tool** with `sheet`, `workbook`, `invoice` and `functions` commands.

## Requirements and setup

Dart SDK 3.13 or newer.

```
dart pub get
```

## Command line

```
dart run cellar <command> [args]
dart run cellar <file.csv> [options]        (shorthand for the sheet command)
```

| Command | What it does |
|---|---|
| `sheet <file.csv>` | Load a CSV sheet, optionally edit it, print it |
| `workbook <file.json>` | Load a JSON workbook, optionally edit it, print a sheet |
| `invoice <file.json>` | Compute an invoice and render it as text or HTML |
| `functions` | List every supported function name |
| `help` | Show usage |

Sheet options:

| Option | Meaning |
|---|---|
| `--set REF=CONTENT` | Set a cell before printing; keep the leading `=` for a formula (`--set B1==A1+1`) |
| `--show REF` | Print the value and the raw content of one cell (repeatable) |
| `--formulas` | Print raw contents instead of computed values |
| `--csv-values` | Write the computed sheet as CSV |
| `--csv-formulas` | Write the raw contents as CSV |

Workbook options:

| Option | Meaning |
|---|---|
| `--sheet NAME` | Sheet to print and default sheet for `--set` and `--show` (default: the first sheet) |
| `--set [NAME!]REF=CONTENT` | Set a cell, optionally on a named sheet |
| `--show [NAME!]REF` | Print the value and the raw content of one cell |
| `--formulas` | Print raw contents instead of computed values |

Invoice options:

| Option | Meaning |
|---|---|
| `--html` | Render HTML instead of text |
| `--out FILE` | Write the render to a file instead of standard output |

Invalid options, missing files and malformed `--set` arguments exit with status 2.

### Sheet

`example/invoice.csv` is a small order with line totals, tax and a conditional note:

```
$ dart run cellar example/invoice.csv
   |         A |   B |    C |           D
---+-----------+-----+------+------------
 1 |      Item | Qty | Unit |   LineTotal
 2 |    Widget |   3 |  4.5 |        13.5
 3 |    Gadget |   5 |    2 |          10
 4 |     Gizmo |   2 | 9.99 |       19.98
 5 |  Subtotal |     |      |       43.48
 6 | Tax 23pct |     |      |          10
 7 |     Total |     |      |       53.48
 8 |     Items |     |      |           3
 9 |  Avg line |     |      |       14.49
10 |      Note |     |      | large order
```

Changing a quantity recomputes the dependent cells:

```
$ dart run cellar example/invoice.csv --set B2=10 --show D2 --show D7 --show D10
D2: value=45  content==B2*C2
D7: value=92.23  content==D5+D6
D10: value=large order  content==IF(D7>40,"large order","small order")
```

Adding a formula cell and exporting computed values:

```
$ dart run cellar example/invoice.csv --set E1==D7*2 --csv-values
Item,Qty,Unit,LineTotal,106.96
Widget,3,4.5,13.5,
Gadget,5,2,10,
Gizmo,2,9.99,19.98,
Subtotal,,,43.48,
Tax 23pct,,,10,
Total,,,53.48,
Items,,,3,
Avg line,,,14.49,
Note,,,large order,
```

`--formulas` prints the grid of raw contents and `--csv-formulas` writes them back as CSV with
proper quoting:

```
$ dart run cellar example/invoice.csv --csv-formulas
Item,Qty,Unit,LineTotal
Widget,3,4.50,=B2*C2
Gadget,5,2.00,=B3*C3
Gizmo,2,9.99,=B4*C4
Subtotal,,,=SUM(D2:D4)
Tax 23pct,,,"=ROUND(D5*0.23,2)"
Total,,,=D5+D6
Items,,,=COUNT(B2:B4)
Avg line,,,"=ROUND(AVERAGE(D2:D4),2)"
Note,,,"=IF(D7>40,""large order"",""small order"")"
```

### Workbook

`example/budget.json` has three sheets. `Summary` uses a defined name (`IncomeAmounts`), a
cross-sheet range, `INDEX`/`MATCH` and cell formats:

```
$ dart run cellar workbook example/budget.json
# Summary
  |               A |           B
--+-----------------+------------
1 |            Item |       Value
2 |          Income | 9,735.50 zl
3 |        Expenses | 5,550.00 zl
4 |         Balance | 4,185.50 zl
5 |    Savings rate |       43.0%
6 | Largest expense |        Rent
```

An edit on one sheet propagates to another:

```
$ dart run cellar workbook example/budget.json --set Expenses!B2=2500 --show Summary!B4 --show Summary!B5
B4: value=4,885.50 zl  content==B2-B3
B5: value=50.2%  content==IF(B2=0,0,B4/B2)
```

`--sheet Expenses` prints another sheet.

### Invoice

```
$ dart run cellar invoice example/invoice.json
INVOICE FV/2026/08/001
Issued: 2026-08-28   Due: 2026-09-11

Seller: Example Software Sp. z o.o.
        ul. Przykladowa 1, 00-001 Warszawa
        Tax ID: PL1234567890
Buyer:  Acme Corp
        ul. Klienta 5, 30-001 Krakow
        Tax ID: PL9876543210

#  Description              Qty  Unit  Unit net  Disc       Net  VAT
--------------------------------------------------------------------
1  Consulting hours          12  h       150.00     -  1 800.00  23%
2  Annual software license    2  pcs     500.00   10%    900.00  23%
3  Printed manual             4  pcs      25.00     -    100.00  5%

VAT summary (PLN):
Rate       Net     VAT     Gross
--------------------------------
23%   2 700.00  621.00  3 321.00
5%      100.00    5.00    105.00

Subtotal (net): 2 800.00 zl
VAT total:      626.00 zl
TOTAL:          3 426.00 zl

Payment terms: 14 days, transfer

Notes: Thank you for your business.
```

```
$ dart run cellar invoice example/invoice.json --html --out invoice.html
Wrote HTML invoice to invoice.html
```

Invoice JSON fields:

| Field | Meaning |
|---|---|
| `number` | Invoice number (required) |
| `issueDate`, `dueDate` | Dates as `YYYY-MM-DD`; `dueDate` is optional |
| `currency` | ISO code, default `PLN` |
| `seller`, `buyer` | Objects with `name` (required), `address`, `taxId`, `email` |
| `paymentTerms`, `notes` | Optional text |
| `reportingCurrency`, `reportingRate` | Optional conversion of the totals |
| `lines` | Array of `description`, `quantity`, `unitPrice`, `vat`, optional `discount` and `unit` |

`vat` is a percentage number (`23`) or a label (`"8%"`, `"0%"`, `"zw"`, `"exempt"`). `discount` is
a fraction (`0.1` is 10%). `unit` defaults to `pcs`.

### Functions

```
$ dart run cellar functions
ABS
ACOS
AND
...
```

## Library

`example/main.dart` (run with `dart run example/main.dart`):

```dart
import 'package:cellar/cellar.dart';

void main() {
  final sheet = Sheet();
  sheet.setValue('A1', '10');
  sheet.setValue('A2', '20');
  sheet.setValue('B1', '=SUM(A1:A2)');
  print(sheet.valueOf('B1').display());               // 30

  sheet.setValue('A2', '32');
  print(sheet.valueOf('B1').display());               // 42

  sheet.setValue('C1', '=C2+1');
  sheet.setValue('C2', '=C1+1');
  print(sheet.valueOf('C1').display());               // #CYCLE!

  final workbook = Workbook();
  final prices = workbook.addSheet('Prices');
  final orders = workbook.addSheet('Orders');
  prices.setValue('A1', 'apple');
  prices.setValue('B1', '1.20');
  prices.setValue('A2', 'pear');
  prices.setValue('B2', '1.75');
  workbook.defineName('PriceList', 'Prices!A1:B2');
  orders.setValue('A1', 'pear');
  orders.setValue('B1', '4');
  orders.setValue('C1', '=VLOOKUP(A1,PriceList,2,FALSE)*B1');
  orders.setFormat('C1', const NumberFormat.currency(r'$'));
  print(orders.displayAt(CellAddress.parse('C1')));   // $7.00

  final sales = Sheet('Sales');
  importCsv(sales, 'Region,Product,Units\nNorth,Tea,5\nSouth,Tea,3\nNorth,Coffee,7\n');
  final pivot = DataTable.fromSheet(sales).pivot(
    rowKey: 'Region',
    columnKey: 'Product',
    valueColumn: 'Units',
  );
  print(renderTextRows(pivot.toRows()));
  // Region  Tea  Coffee
  // North   5    7
  // South   3

  final invoice = Invoice(
    number: InvoiceSequence('INV/{year}/{seq:4}').next(DateTime(2026, 3, 1)),
    issueDate: DateTime(2026, 3, 1),
    seller: const Party(name: 'Example Seller'),
    buyer: const Party(name: 'Example Buyer'),
    currency: Currency.eur,
    lines: [
      InvoiceLine(
        description: 'Support plan',
        quantity: 3,
        unitPrice: Money.of(99.90, Currency.eur),
        vat: VatRate.standard,
      ),
    ],
  );
  print('${invoice.number}: ${invoice.totalGross.format()}'); // INV/2026/0001: 368.63 EUR
}
```

Other entry points exported by `package:cellar/cellar.dart`:

- `Workbook`: `addSheet`, `sheet`, `sheetByName`, `removeSheet`, `defineName`, `resolveName`,
  `recalculate`.
- `Sheet`: `setValue`, `setCell`, `clear`, `valueOf`, `valueAt`, `rawAt`, `displayAt`,
  `setFormat`, `dimensions`.
- `parseFormula`, `Lexer`, `Parser` and the AST classes for working with formulas directly.
- `parseCsv`, `encodeCsv`, `importCsv`, `exportValues`, `exportFormulas`.
- `encodeWorkbookJson`, `decodeWorkbookJson`.
- `NumberFormat` with `fromCode` and `toCode`.
- `DataTable` (`fromSheet`, `sortBy`, `sortByAll`, `filterRows`, `where`, `selectColumns`,
  `groupBy`, `pivot`, `toRows`), `PivotTable`, `Aggregation`, `Aggregator`.
- `renderGrid` and `renderTextRows` for plain text output.
- Invoices: `Invoice`, `InvoiceLine`, `Party`, `VatRate`, `Money`, `Currency`, `InvoiceSequence`,
  `invoiceFromJson`, `invoiceFromJsonString`, `encodeInvoiceJson`, `renderInvoiceText`,
  `renderInvoiceHtml`.
- `buildFunctions` returns the function registry, `functionNames` the sorted list of names.

## Formula syntax

A cell whose content starts with `=` is a formula.

| Element | Syntax |
|---|---|
| Numbers | `42`, `3.14`, `.5` |
| Text | `"double quoted"`, a doubled quote `""` inside is a literal quote |
| Booleans | `TRUE`, `FALSE` (case-insensitive) |
| Errors | `#DIV/0!`, `#REF!`, `#NAME?`, `#VALUE!`, `#NUM!`, `#N/A`, `#CYCLE!`, `#ERROR!` |
| Cell | `B2`, `$B$2` (the `$` markers are accepted and have no effect) |
| Range | `A1:C3` |
| Other sheet | `Data!B2`, `Data!A1:A9`, `'My Sheet'!A1` |
| Defined name | `PriceList` (refers to a cell or a range) |
| Function call | `SUM(A1:A9, 10)`, names are case-insensitive |

Operators, from lowest to highest precedence:

| Operators | Meaning |
|---|---|
| `=` `<>` `<` `<=` `>` `>=` | Comparison, returns a boolean |
| `&` | Text concatenation |
| `+` `-` | Addition, subtraction |
| `*` `/` `%` | Multiplication, division, remainder (`7%3` is 1) |
| unary `-` `+` | Sign |
| `^` | Power, right-associative (`2^3^2` is 512) |

Evaluation rules:

- Arithmetic converts blanks to 0, booleans to 1 or 0, and numeric text to its number; other text
  gives `#VALUE!`. Division and remainder by zero give `#DIV/0!`.
- Comparison is numeric when both sides are numeric, otherwise a case-insensitive text comparison.
- Aggregating functions (`SUM`, `AVERAGE`, `MAX`, ...) skip text, booleans and blanks inside ranges
  but propagate errors.
- Criteria in `SUMIF`, `COUNTIF`, `AVERAGEIF` and the `*IFS` functions are a value or a text with
  an operator: `">10"`, `"<>done"`, `"=a*"`. Text matching is case-insensitive and supports the
  `*` and `?` wildcards.
- Dates are serial day numbers counted from 1899-12-30, as in common spreadsheet applications.
- A formula that fails to parse evaluates to `#ERROR!`; an unknown function or name to `#NAME?`.

## Functions

138 functions, 141 names including aliases. Optional arguments are in brackets.

### Math (36 functions, 37 names)

| Function | Description |
|---|---|
| `ABS(x)` | Absolute value |
| `SQRT(x)` | Square root, `#NUM!` for negative input |
| `POWER(x, y)` | x raised to y |
| `EXP(x)` | e raised to x |
| `LN(x)`, `LOG10(x)` | Natural and base 10 logarithm |
| `LOG(x, [base])` | Logarithm, base 10 by default |
| `PI()` | Pi |
| `MOD(a, b)` | Remainder with the sign of the divisor |
| `QUOTIENT(a, b)` | Integer part of a division |
| `ROUND(x, [digits])` | Round half away from zero to a number of digits |
| `ROUNDUP(x, [digits])`, `ROUNDDOWN(x, [digits])` | Round away from zero, toward zero |
| `MROUND(x, multiple)` | Round to the nearest multiple |
| `TRUNC(x, [digits])` | Truncate to a number of digits |
| `INT(x)` | Round down to an integer |
| `SIGN(x)` | -1, 0 or 1 |
| `EVEN(x)`, `ODD(x)` | Round away from zero to the next even or odd integer |
| `FLOOR(x, [step])` | Round down to a multiple of step |
| `CEIL(x, [step])`, alias `CEILING` | Round up to a multiple of step |
| `GCD(n, ...)`, `LCM(n, ...)` | Greatest common divisor, least common multiple |
| `FACT(n)` | Factorial |
| `COMBIN(n, k)` | Number of combinations |
| `SIN`, `COS`, `TAN`, `ASIN`, `ACOS`, `ATAN` | Trigonometry in radians |
| `ATAN2(x, y)` | Angle of the point (x, y) |
| `DEGREES(r)`, `RADIANS(d)` | Angle conversion |
| `RAND()` | Random number in [0, 1) |
| `RANDBETWEEN(low, high)` | Random integer in [low, high] |

### Aggregate and conditional (14)

| Function | Description |
|---|---|
| `SUM(v, ...)` | Sum |
| `SUMSQ(v, ...)` | Sum of squares |
| `PRODUCT(v, ...)` | Product |
| `MIN(v, ...)`, `MAX(v, ...)` | Smallest and largest number, 0 when there are none |
| `SUMPRODUCT(range, ...)` | Sum of element-wise products of equally sized ranges |
| `SUMIF(range, criterion, [sumRange])` | Sum where the criterion matches |
| `COUNTIF(range, criterion)` | Count where the criterion matches |
| `AVERAGEIF(range, criterion, [averageRange])` | Average where the criterion matches |
| `SUMIFS(sumRange, range1, criterion1, ...)` | Sum where all criteria match |
| `AVERAGEIFS(averageRange, range1, criterion1, ...)` | Average where all criteria match |
| `COUNTIFS(range1, criterion1, ...)` | Count where all criteria match |
| `MAXIFS(range, range1, criterion1, ...)`, `MINIFS(...)` | Largest or smallest value where all criteria match |

### Statistics (14 functions, 15 names)

| Function | Description |
|---|---|
| `AVERAGE(v, ...)`, alias `AVG` | Arithmetic mean, `#DIV/0!` with no numbers |
| `COUNT(v, ...)` | Count of numbers |
| `COUNTA(v, ...)` | Count of non-blank values |
| `COUNTBLANK(v, ...)` | Count of blank cells |
| `MEDIAN(v, ...)` | Median |
| `MODE(v, ...)` | Most frequent number, `#N/A` when nothing repeats |
| `VAR`, `VARP` | Sample and population variance |
| `STDEV`, `STDEVP` | Sample and population standard deviation |
| `LARGE(range, k)`, `SMALL(range, k)` | k-th largest or smallest number |
| `RANK(x, range, [ascending])` | Position of x in the sorted range |
| `PERCENTILE(range, k)` | Interpolated percentile, k in [0, 1] |

### Text (24 functions, 25 names)

| Function | Description |
|---|---|
| `CONCAT(v, ...)`, alias `CONCATENATE` | Join values as text |
| `TEXTJOIN(delimiter, ignoreEmpty, v, ...)` | Join with a delimiter |
| `LEN(text)` | Length |
| `LEFT(text, [n])`, `RIGHT(text, [n])` | First or last n characters |
| `MID(text, start, length)` | Substring, 1-based start |
| `UPPER`, `LOWER`, `PROPER` | Change case |
| `TRIM(text)` | Strip the ends and collapse inner whitespace |
| `REPT(text, n)` | Repeat |
| `EXACT(a, b)` | Case-sensitive equality |
| `SUBSTITUTE(text, old, new, [instance])` | Replace all or the n-th occurrence |
| `REPLACE(text, start, length, new)` | Replace by position |
| `FIND(needle, text, [start])` | Case-sensitive position, `#VALUE!` when absent |
| `SEARCH(needle, text, [start])` | Case-insensitive position |
| `CHAR(code)`, `CODE(text)` | Character from a code point and back |
| `VALUE(text)` | Parse a number |
| `NUMBERVALUE(text, [decimalSep], [groupSep])` | Parse a number with custom separators |
| `TEXT(value, format)` | Format a number with a format code |
| `REGEXMATCH(text, pattern)` | Whether the pattern matches |
| `REGEXEXTRACT(text, pattern)` | First capture group, or the whole match |
| `REGEXREPLACE(text, pattern, replacement)` | Replace every match |

Regular expressions use Dart `RegExp` syntax.

### Logical (11)

| Function | Description |
|---|---|
| `IF(condition, then, [else])` | Conditional, `FALSE` when the else branch is missing |
| `IFS(condition1, value1, ...)` | First value whose condition is true, `#N/A` otherwise |
| `SWITCH(value, case1, result1, ..., [default])` | Match a value against cases |
| `AND(v, ...)`, `OR(v, ...)`, `XOR(v, ...)` | Logical combination, blanks ignored |
| `NOT(v)` | Negation |
| `TRUE()`, `FALSE()` | Boolean constants |
| `IFERROR(value, fallback)` | Fallback for any error |
| `IFNA(value, fallback)` | Fallback for `#N/A` only |

### Information (11)

| Function | Description |
|---|---|
| `ISBLANK(v)` | Blank cell |
| `ISERROR(v)`, `ISERR(v)`, `ISNA(v)` | Any error, any error except `#N/A`, only `#N/A` |
| `ISNUMBER(v)`, `ISTEXT(v)`, `ISNONTEXT(v)`, `ISLOGICAL(v)` | Type tests |
| `NA()` | Produce `#N/A` |
| `N(v)` | Number for numbers and booleans, 0 otherwise |
| `TYPE(v)` | 1 number, 2 text, 4 boolean, 16 error |

### Lookup and reference (10)

| Function | Description |
|---|---|
| `INDEX(range, n)`, `INDEX(range, row, column)` | Value by position, `#REF!` out of range |
| `MATCH(value, range, [type])` | Position; type 1 sorted ascending (default), 0 exact, -1 sorted descending |
| `VLOOKUP(key, range, column, [approximate])` | Search the first column, approximate by default |
| `HLOOKUP(key, range, row, [approximate])` | Search the first row |
| `LOOKUP(key, searchRange, [resultRange])` | Approximate search, value from a parallel range |
| `CHOOSE(index, v1, v2, ...)` | Pick an argument by position |
| `ROWS(range)`, `COLUMNS(range)` | Size of a range |
| `ROW(ref)`, `COLUMN(ref)` | Row or column number of a reference |

### Date (11)

| Function | Description |
|---|---|
| `DATE(year, month, day)` | Serial number of a date |
| `TODAY()`, `NOW()` | Current date, current date and time |
| `YEAR(d)`, `MONTH(d)`, `DAY(d)` | Date parts |
| `WEEKDAY(d, [mode])` | Day of week; mode 1 Sunday=1 (default), 2 Monday=1, 3 Monday=0 |
| `DATEDIF(start, end, unit)` | Difference in `D`, `M`, `Y`, `MD`, `YM` or `YD` |
| `EDATE(d, months)` | Same day a number of months away, clamped to the month end |
| `EOMONTH(d, months)` | Last day of the month a number of months away |
| `DAYS(end, start)` | Number of days between two dates |

### Financial (7)

| Function | Description |
|---|---|
| `PMT(rate, nper, pv, [fv], [type])` | Payment per period |
| `FV(rate, nper, pmt, [pv], [type])` | Future value |
| `PV(rate, nper, pmt, [fv], [type])` | Present value |
| `NPER(rate, pmt, pv, [fv], [type])` | Number of periods |
| `RATE(nper, pmt, pv, [fv], [type], [guess])` | Interest rate per period (Newton iteration) |
| `NPV(rate, flow, ...)` | Net present value of flows at the end of each period |
| `IRR(flows, [guess])` | Internal rate of return (bisection, Newton as a fallback) |

`type` is 0 for payments at the end of a period and 1 for the start.

## Architecture

```
text --Lexer--> tokens --Parser--> Expr (AST) --EvalContext--> CellValue
                                       |
                    Workbook: sheets, names, function registry, dependency graph
```

- `lexer.dart` and `tokens.dart` turn formula text into tokens: numbers, text, error literals,
  identifiers, quoted sheet names, cell references and operators.
- `parser.dart` is a recursive descent parser with one method per precedence level. It produces
  the sealed `Expr` hierarchy in `ast.dart` (literals, `RefNode`, `RangeNode`, `NameNode`,
  `UnaryOp`, `BinaryOp`, `FuncCall`).
- `evaluator.dart` walks the AST. `EvalContext` resolves references and names through the
  workbook, implements coercion and comparison, and dispatches calls to the function registry.
  Errors travel as `EvalException` and are turned back into an `ErrorValue` at the cell boundary.
- `functions/` holds the registry, one file per group. Each function is a
  `CellValue Function(List<Expr> args, EvalContext ctx)` and receives unevaluated arguments, which
  lets `IF`, `IFERROR` and friends evaluate lazily and lets range functions see the range itself.
- `workbook.dart` owns the sheets, the defined names and the graph. Each `Cell` keeps sets of
  precedents and dependents as `(Sheet, CellAddress)` records. Setting a cell removes its old
  edges, parses the formula, collects new precedents, then recomputes the transitive dependents in
  topological order. Bulk loads (CSV, JSON) set cells without recomputing and run one full
  recalculation at the end.
- `sheet.dart` is the per-sheet facade, `values.dart` the value types, `format.dart` number
  formats, `dates.dart` serial date arithmetic.
- `csv.dart`, `workbook_json.dart` and `grid.dart` handle storage and text output; `table.dart` is
  the data table layer; `invoice/` is the invoice module, independent of the formula engine.

## Project layout

```
bin/cellar.dart            command line tool
lib/cellar.dart            public library exports
lib/src/                   engine, storage, formats, data tables
lib/src/functions/         built-in functions by group
lib/src/invoice/           money, invoice model, JSON loader, renderers
example/main.dart          library usage
example/invoice.csv        sample sheet for the sheet command
example/budget.json        sample workbook for the workbook command
example/invoice.json       sample invoice for the invoice command
test/                      unit tests
```

## Tests

```
dart analyze
dart test
```

The suite has 152 tests in 18 files: lexer and parser, operators and error propagation, the
dependency graph and cycle detection, every function group, number formats, CSV round trips,
workbooks and their JSON format, data tables, money arithmetic and invoices.

## Limitations

- No exponent notation in formula numbers: `=1e3` does not parse. Plain cell input such as `1e3`
  is still read as a number.
- Unary minus binds looser than `^`, so `=-2^2` is -4.
- Defined names consist of letters and underscores. A name followed by digits, such as `Rate2`, is
  read as a cell reference.
- No array formulas or spilling. A bare range outside a function argument gives `#VALUE!`.
- Ranges are expanded cell by cell in the dependency graph, and whole-column or whole-row
  references (`A:A`, `1:1`) are not supported.
- `$` markers are accepted but there is no copy or fill, so absolute and relative references
  behave the same.
- `TODAY`, `NOW`, `RAND` and `RANDBETWEEN` are not volatile: they are re-evaluated only when their
  cell, a precedent or the whole workbook is recalculated.
- Number formats cover numbers only; there are no date or time display formats.
- CSV is comma-separated only and maps to a single sheet. Formats and defined names are kept only
  in the JSON workbook format. There is no XLSX or ODS support.
- Function behaviour follows common spreadsheet conventions but is not guaranteed to match any
  particular application in every edge case.

## License

MIT, see [LICENSE](LICENSE).
