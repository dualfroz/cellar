import 'address.dart';
import 'sheet.dart';

List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var field = StringBuffer();
  var record = <String>[];
  var inQuotes = false;
  var fieldStarted = false;
  var index = 0;

  while (index < input.length) {
    final ch = input[index];
    if (inQuotes) {
      if (ch == '"') {
        if (index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index += 2;
          continue;
        }
        inQuotes = false;
        index++;
        continue;
      }
      field.write(ch);
      index++;
      continue;
    }

    switch (ch) {
      case '"':
        inQuotes = true;
        fieldStarted = true;
        index++;
      case ',':
        record.add(field.toString());
        field = StringBuffer();
        fieldStarted = false;
        index++;
      case '\r':
        index++;
      case '\n':
        record.add(field.toString());
        rows.add(record);
        field = StringBuffer();
        record = <String>[];
        fieldStarted = false;
        index++;
      default:
        field.write(ch);
        fieldStarted = true;
        index++;
    }
  }

  if (field.isNotEmpty || record.isNotEmpty || fieldStarted) {
    record.add(field.toString());
    rows.add(record);
  }
  return rows;
}

String encodeCsv(List<List<String>> rows) =>
    rows.map((record) => record.map(_encodeField).join(',')).join('\n');

String _encodeField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

void importCsv(Sheet sheet, String input) {
  final rows = parseCsv(input);
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final record = rows[rowIndex];
    for (var colIndex = 0; colIndex < record.length; colIndex++) {
      final field = record[colIndex];
      if (field.isEmpty) continue;
      sheet.setCell(CellAddress(colIndex, rowIndex), field, recalculate: false);
    }
  }
  sheet.recalculate();
}

String exportValues(Sheet sheet) => _export(sheet, formulas: false);

String exportFormulas(Sheet sheet) => _export(sheet, formulas: true);

String _export(Sheet sheet, {required bool formulas}) {
  final dimensions = sheet.dimensions();
  final rows = <List<String>>[];
  for (var row = 0; row < dimensions.rows; row++) {
    final record = <String>[];
    for (var col = 0; col < dimensions.cols; col++) {
      final address = CellAddress(col, row);
      record.add(formulas ? sheet.rawAt(address) : sheet.valueAt(address).display());
    }
    rows.add(record);
  }
  return encodeCsv(rows);
}
