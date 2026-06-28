import 'address.dart';
import 'values.dart';

sealed class Expr {
  const Expr();
}

class NumberLit extends Expr {
  final double value;
  const NumberLit(this.value);
}

class TextLit extends Expr {
  final String value;
  const TextLit(this.value);
}

class BoolLit extends Expr {
  final bool value;
  const BoolLit(this.value);
}

class ErrorLit extends Expr {
  final ErrorKind kind;
  const ErrorLit(this.kind);
}

class RefNode extends Expr {
  final CellAddress address;
  final String? sheet;
  const RefNode(this.address, [this.sheet]);
}

class RangeNode extends Expr {
  final CellAddress start;
  final CellAddress end;
  final String? sheet;
  const RangeNode(this.start, this.end, [this.sheet]);
}

class NameNode extends Expr {
  final String name;
  const NameNode(this.name);
}

class UnaryOp extends Expr {
  final String op;
  final Expr operand;
  const UnaryOp(this.op, this.operand);
}

class BinaryOp extends Expr {
  final String op;
  final Expr left;
  final Expr right;
  const BinaryOp(this.op, this.left, this.right);
}

class FuncCall extends Expr {
  final String name;
  final List<Expr> args;
  const FuncCall(this.name, this.args);
}
