import 'address.dart';
import 'sheet.dart';
import 'values.dart';

enum Aggregator { sum, count, average, min, max, first }

class Aggregation {
  final String column;
  final Aggregator aggregator;
  final String alias;
  const Aggregation(this.column, this.aggregator, this.alias);
}

class DataTable {
  final List<String> headers;
  final List<List<CellValue>> rows;

  DataTable(this.headers, this.rows);

  factory DataTable.fromSheet(
    Sheet sheet, {
    CellAddress? topLeft,
    CellAddress? bottomRight,
    bool headerRow = true,
  }) {
    final origin = topLeft ?? const CellAddress(0, 0);
    final dimensions = sheet.dimensions();
    final end = bottomRight ?? CellAddress(dimensions.cols - 1, dimensions.rows - 1);
    final grid = <List<CellValue>>[];
    for (var row = origin.row; row <= end.row; row++) {
      final record = <CellValue>[];
      for (var col = origin.col; col <= end.col; col++) {
        record.add(sheet.valueAt(CellAddress(col, row)));
      }
      grid.add(record);
    }
    if (headerRow && grid.isNotEmpty) {
      final headers = [for (final cell in grid.first) cell.display()];
      return DataTable(headers, grid.skip(1).toList());
    }
    final width = grid.isEmpty ? end.col - origin.col + 1 : grid.first.length;
    final headers = [for (var i = 0; i < width; i++) columnLabel(origin.col + i)];
    return DataTable(headers, grid);
  }

  int get rowCount => rows.length;

  int columnIndex(String header) {
    final index = headers.indexOf(header);
    if (index < 0) throw ArgumentError('No such column: $header');
    return index;
  }

  CellValue cell(int row, String column) => rows[row][columnIndex(column)];

  DataTable sortBy(String column, {bool ascending = true}) {
    final index = columnIndex(column);
    final sorted = [...rows]
      ..sort((a, b) {
        final result = compareValues(a[index], b[index]);
        return ascending ? result : -result;
      });
    return DataTable(headers, sorted);
  }

  DataTable sortByAll(List<String> columns, {List<bool>? ascending}) {
    final indices = [for (final column in columns) columnIndex(column)];
    final directions = ascending ?? List<bool>.filled(columns.length, true);
    final sorted = [...rows]
      ..sort((a, b) {
        for (var i = 0; i < indices.length; i++) {
          final result = compareValues(a[indices[i]], b[indices[i]]);
          if (result != 0) return directions[i] ? result : -result;
        }
        return 0;
      });
    return DataTable(headers, sorted);
  }

  DataTable filterRows(bool Function(List<CellValue>) predicate) =>
      DataTable(headers, rows.where(predicate).toList());

  DataTable where(String column, bool Function(CellValue) test) {
    final index = columnIndex(column);
    return filterRows((row) => test(row[index]));
  }

  DataTable selectColumns(List<String> columns) {
    final indices = [for (final column in columns) columnIndex(column)];
    return DataTable(
      columns,
      [for (final row in rows) [for (final index in indices) row[index]]],
    );
  }

  DataTable groupBy(List<String> keyColumns, List<Aggregation> aggregations) {
    final keyIndices = [for (final column in keyColumns) columnIndex(column)];
    final valueIndices = [for (final aggregation in aggregations) columnIndex(aggregation.column)];
    final order = <String>[];
    final keys = <String, List<CellValue>>{};
    final buckets = <String, List<List<CellValue>>>{};
    for (final row in rows) {
      final keyValues = [for (final index in keyIndices) row[index]];
      final signature = keyValues.map((value) => value.display()).join('');
      if (!buckets.containsKey(signature)) {
        order.add(signature);
        keys[signature] = keyValues;
        buckets[signature] = [];
      }
      buckets[signature]!.add(row);
    }

    final resultHeaders = [...keyColumns, for (final aggregation in aggregations) aggregation.alias];
    final resultRows = <List<CellValue>>[];
    for (final signature in order) {
      final record = <CellValue>[...keys[signature]!];
      for (var i = 0; i < aggregations.length; i++) {
        final columnValues = [for (final row in buckets[signature]!) row[valueIndices[i]]];
        record.add(aggregateValues(columnValues, aggregations[i].aggregator));
      }
      resultRows.add(record);
    }
    return DataTable(resultHeaders, resultRows);
  }

  PivotTable pivot({
    required String rowKey,
    required String columnKey,
    required String valueColumn,
    Aggregator aggregator = Aggregator.sum,
  }) {
    final rowIndex = columnIndex(rowKey);
    final colIndex = columnIndex(columnKey);
    final valueIndex = columnIndex(valueColumn);

    final rowLabels = <String>[];
    final colLabels = <String>[];
    final buckets = <String, Map<String, List<CellValue>>>{};
    for (final row in rows) {
      final rowLabel = row[rowIndex].display();
      final colLabel = row[colIndex].display();
      if (!rowLabels.contains(rowLabel)) rowLabels.add(rowLabel);
      if (!colLabels.contains(colLabel)) colLabels.add(colLabel);
      final byColumn = buckets.putIfAbsent(rowLabel, () => {});
      byColumn.putIfAbsent(colLabel, () => []).add(row[valueIndex]);
    }

    final matrix = <List<CellValue>>[];
    for (final rowLabel in rowLabels) {
      final record = <CellValue>[];
      for (final colLabel in colLabels) {
        final cellValues = buckets[rowLabel]?[colLabel];
        record.add(cellValues == null
            ? const BlankValue()
            : aggregateValues(cellValues, aggregator));
      }
      matrix.add(record);
    }
    return PivotTable(rowKey, rowLabels, colLabels, matrix);
  }

  List<List<String>> toRows({bool includeHeader = true}) => [
        if (includeHeader) headers,
        for (final row in rows) [for (final cell in row) cell.display()],
      ];
}

class PivotTable {
  final String rowKeyName;
  final List<String> rowLabels;
  final List<String> columnLabels;
  final List<List<CellValue>> values;

  PivotTable(this.rowKeyName, this.rowLabels, this.columnLabels, this.values);

  CellValue at(String rowLabel, String columnLabel) {
    final r = rowLabels.indexOf(rowLabel);
    final c = columnLabels.indexOf(columnLabel);
    if (r < 0 || c < 0) return const BlankValue();
    return values[r][c];
  }

  List<List<String>> toRows() => [
        [rowKeyName, ...columnLabels],
        for (var r = 0; r < rowLabels.length; r++)
          [rowLabels[r], for (final cell in values[r]) cell.display()],
      ];
}

CellValue aggregateValues(List<CellValue> values, Aggregator aggregator) {
  final numbers = [for (final value in values) if (value is NumberValue) value.value];
  switch (aggregator) {
    case Aggregator.count:
      return NumberValue(values.where((value) => value is! BlankValue).length.toDouble());
    case Aggregator.first:
      return values.isEmpty ? const BlankValue() : values.first;
    case Aggregator.sum:
      return NumberValue(numbers.fold(0.0, (a, b) => a + b));
    case Aggregator.average:
      if (numbers.isEmpty) return const BlankValue();
      return NumberValue(numbers.reduce((a, b) => a + b) / numbers.length);
    case Aggregator.min:
      if (numbers.isEmpty) return const BlankValue();
      return NumberValue(numbers.reduce((a, b) => a < b ? a : b));
    case Aggregator.max:
      if (numbers.isEmpty) return const BlankValue();
      return NumberValue(numbers.reduce((a, b) => a > b ? a : b));
  }
}

int compareValues(CellValue a, CellValue b) {
  final aNumber = a is NumberValue ? a.value : null;
  final bNumber = b is NumberValue ? b.value : null;
  if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
  return a.display().toUpperCase().compareTo(b.display().toUpperCase());
}
