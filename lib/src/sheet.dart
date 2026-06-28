import 'address.dart';
import 'ast.dart';
import 'format.dart';
import 'values.dart';
import 'workbook.dart';

typedef GlobalCell = (Sheet sheet, CellAddress address);

class Cell {
  String raw;
  Expr? formula;
  CellValue value;
  NumberFormat? format;
  Set<GlobalCell> precedents;
  Set<GlobalCell> dependents;

  Cell()
      : raw = '',
        formula = null,
        value = const BlankValue(),
        format = null,
        precedents = <GlobalCell>{},
        dependents = <GlobalCell>{};

  bool get isFormula => formula != null;

  bool get isOccupied => raw.isNotEmpty || formula != null;
}

class Sheet {
  final String name;
  final Workbook workbook;
  final Map<CellAddress, Cell> cells = {};

  Sheet.internal(this.name, this.workbook);

  factory Sheet([String name = 'Sheet1']) {
    final book = Workbook.empty();
    return book.addSheet(name);
  }

  Iterable<MapEntry<CellAddress, Cell>> get occupiedCells =>
      cells.entries.where((entry) => entry.value.isOccupied);

  Cell? cellAt(CellAddress address) => cells[address];

  CellValue valueAt(CellAddress address) => cells[address]?.value ?? const BlankValue();

  CellValue valueOf(String reference) => valueAt(CellAddress.parse(reference));

  String rawAt(CellAddress address) => cells[address]?.raw ?? '';

  String displayAt(CellAddress address) {
    final cell = cells[address];
    if (cell == null) return '';
    final format = cell.format;
    if (format != null) return format.apply(cell.value);
    return cell.value.display();
  }

  NumberFormat? formatAt(CellAddress address) => cells[address]?.format;

  void setFormat(String reference, NumberFormat? format) =>
      setFormatAt(CellAddress.parse(reference), format);

  void setFormatAt(CellAddress address, NumberFormat? format) {
    final cell = cells.putIfAbsent(address, Cell.new);
    cell.format = format;
  }

  void setValue(String reference, String input) => setCell(CellAddress.parse(reference), input);

  void setCell(CellAddress address, String input, {bool recalculate = true}) {
    workbook.setCell(this, address, input, recalculate: recalculate);
  }

  void clear(CellAddress address) => workbook.clearCell(this, address);

  void recalculate() => workbook.recalculate();

  ({int cols, int rows}) dimensions() {
    var maxCol = -1;
    var maxRow = -1;
    for (final entry in occupiedCells) {
      if (entry.key.col > maxCol) maxCol = entry.key.col;
      if (entry.key.row > maxRow) maxRow = entry.key.row;
    }
    return (cols: maxCol + 1, rows: maxRow + 1);
  }
}
