import 'address.dart';
import 'sheet.dart';

String renderGrid(Sheet sheet, {bool formulas = false, bool useFormat = true}) {
  final dimensions = sheet.dimensions();
  if (dimensions.rows == 0) return '(empty sheet)\n';

  String contentAt(int col, int row) {
    final address = CellAddress(col, row);
    if (formulas) return sheet.rawAt(address);
    return useFormat ? sheet.displayAt(address) : sheet.valueAt(address).display();
  }

  final colWidths = <int>[];
  for (var col = 0; col < dimensions.cols; col++) {
    var width = columnLabel(col).length;
    for (var row = 0; row < dimensions.rows; row++) {
      final length = contentAt(col, row).length;
      if (length > width) width = length;
    }
    colWidths.add(width);
  }

  final gutter = dimensions.rows.toString().length;
  final buffer = StringBuffer();

  buffer.write(' ' * gutter);
  for (var col = 0; col < dimensions.cols; col++) {
    buffer.write(' | ');
    buffer.write(columnLabel(col).padLeft(colWidths[col]));
  }
  buffer.writeln();

  buffer.write('-' * gutter);
  for (var col = 0; col < dimensions.cols; col++) {
    buffer.write('-+-');
    buffer.write('-' * colWidths[col]);
  }
  buffer.writeln();

  for (var row = 0; row < dimensions.rows; row++) {
    buffer.write((row + 1).toString().padLeft(gutter));
    for (var col = 0; col < dimensions.cols; col++) {
      buffer.write(' | ');
      buffer.write(contentAt(col, row).padLeft(colWidths[col]));
    }
    buffer.writeln();
  }

  return buffer.toString();
}

String renderTextRows(List<List<String>> rows) {
  if (rows.isEmpty) return '';
  final columns = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
  final widths = List<int>.filled(columns, 0);
  for (final row in rows) {
    for (var c = 0; c < row.length; c++) {
      if (row[c].length > widths[c]) widths[c] = row[c].length;
    }
  }
  final buffer = StringBuffer();
  for (final row in rows) {
    final cells = <String>[];
    for (var c = 0; c < columns; c++) {
      final value = c < row.length ? row[c] : '';
      cells.add(value.padRight(widths[c]));
    }
    buffer.writeln(cells.join('  ').trimRight());
  }
  return buffer.toString();
}
