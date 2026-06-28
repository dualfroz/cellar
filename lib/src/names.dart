import 'address.dart';
import 'sheet.dart';

sealed class NameTarget {
  const NameTarget();
}

class CellName extends NameTarget {
  final Sheet sheet;
  final CellAddress address;
  const CellName(this.sheet, this.address);
}

class RangeName extends NameTarget {
  final Sheet sheet;
  final CellAddress start;
  final CellAddress end;
  const RangeName(this.sheet, this.start, this.end);
}
