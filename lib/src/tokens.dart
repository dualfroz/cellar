import 'values.dart';

enum TokenType {
  number,
  text,
  identifier,
  quotedName,
  cellRef,
  errorLit,
  bang,
  plus,
  minus,
  star,
  slash,
  caret,
  percent,
  amp,
  eq,
  neq,
  lt,
  lte,
  gt,
  gte,
  lparen,
  rparen,
  comma,
  colon,
  eof,
}

class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;

  const Token(this.type, this.lexeme, [this.literal]);

  double get numberValue => literal as double;
  String get textValue => literal as String;
  ErrorKind get errorKind => literal as ErrorKind;

  @override
  String toString() => 'Token(${type.name}, $lexeme)';
}
