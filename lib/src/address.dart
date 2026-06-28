final RegExp _addressPattern = RegExp(r'^\$?([A-Za-z]+)\$?([0-9]+)$');

int columnIndex(String letters) {
  var index = 0;
  for (final unit in letters.toUpperCase().codeUnits) {
    index = index * 26 + (unit - 0x41 + 1);
  }
  return index - 1;
}

String columnLabel(int index) {
  var remaining = index + 1;
  final units = <int>[];
  while (remaining > 0) {
    final position = (remaining - 1) % 26;
    units.add(0x41 + position);
    remaining = (remaining - 1) ~/ 26;
  }
  return String.fromCharCodes(units.reversed);
}

class CellAddress {
  final int col;
  final int row;

  const CellAddress(this.col, this.row);

  factory CellAddress.parse(String reference) {
    final match = _addressPattern.firstMatch(reference.trim());
    if (match == null) {
      throw FormatException('Invalid cell reference: $reference');
    }
    return CellAddress(columnIndex(match.group(1)!), int.parse(match.group(2)!) - 1);
  }

  String get label => '${columnLabel(col)}${row + 1}';

  @override
  bool operator ==(Object other) => other is CellAddress && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => label;
}

List<CellAddress> expandRange(CellAddress start, CellAddress end) {
  final minCol = start.col < end.col ? start.col : end.col;
  final maxCol = start.col > end.col ? start.col : end.col;
  final minRow = start.row < end.row ? start.row : end.row;
  final maxRow = start.row > end.row ? start.row : end.row;
  final cells = <CellAddress>[];
  for (var row = minRow; row <= maxRow; row++) {
    for (var col = minCol; col <= maxCol; col++) {
      cells.add(CellAddress(col, row));
    }
  }
  return cells;
}

int rangeRowCount(CellAddress start, CellAddress end) => (start.row - end.row).abs() + 1;

int rangeColCount(CellAddress start, CellAddress end) => (start.col - end.col).abs() + 1;
