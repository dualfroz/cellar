import 'package:cellar/cellar.dart';
import 'package:test/test.dart';

double num(CellValue value) => (value as NumberValue).value;

Sheet salesSheet() {
  final sheet = Sheet();
  final rows = [
    ['Region', 'Product', 'Amount'],
    ['North', 'A', '100'],
    ['South', 'A', '150'],
    ['North', 'B', '200'],
    ['South', 'B', '50'],
    ['North', 'A', '75'],
  ];
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      sheet.setCell(CellAddress(c, r), rows[r][c]);
    }
  }
  return sheet;
}

void main() {
  group('data table', () {
    test('reads a header row from a sheet', () {
      final table = DataTable.fromSheet(salesSheet());
      expect(table.headers, ['Region', 'Product', 'Amount']);
      expect(table.rowCount, 5);
    });

    test('sortBy descending', () {
      final sorted = DataTable.fromSheet(salesSheet()).sortBy('Amount', ascending: false);
      expect(num(sorted.cell(0, 'Amount')), 200);
      expect(num(sorted.cell(4, 'Amount')), 50);
    });

    test('filter by a column predicate', () {
      final filtered = DataTable.fromSheet(salesSheet())
          .where('Region', (value) => value.display() == 'North');
      expect(filtered.rowCount, 3);
    });

    test('groupBy with sum and count aggregations', () {
      final grouped = DataTable.fromSheet(salesSheet()).groupBy(
        ['Region'],
        const [
          Aggregation('Amount', Aggregator.sum, 'Total'),
          Aggregation('Amount', Aggregator.count, 'Lines'),
        ],
      );
      expect(grouped.headers, ['Region', 'Total', 'Lines']);
      expect(num(grouped.cell(0, 'Total')), 375);
      expect(num(grouped.cell(0, 'Lines')), 3);
      expect(num(grouped.cell(1, 'Total')), 200);
    });

    test('pivot on region by product', () {
      final pivot = DataTable.fromSheet(salesSheet()).pivot(
        rowKey: 'Region',
        columnKey: 'Product',
        valueColumn: 'Amount',
      );
      expect(pivot.rowLabels, ['North', 'South']);
      expect(pivot.columnLabels, ['A', 'B']);
      expect(num(pivot.at('North', 'A')), 175);
      expect(num(pivot.at('South', 'B')), 50);
    });

    test('selectColumns projects a subset', () {
      final projected = DataTable.fromSheet(salesSheet()).selectColumns(['Product', 'Amount']);
      expect(projected.headers, ['Product', 'Amount']);
      expect(projected.rows.first.length, 2);
    });
  });
}
