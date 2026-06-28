import 'address.dart';
import 'ast.dart';
import 'lexer.dart';
import 'tokens.dart';

class FormulaException implements Exception {
  final String message;
  const FormulaException(this.message);

  @override
  String toString() => 'FormulaException: $message';
}

Expr parseFormula(String body) => Parser.forFormula(body).parse();

class Parser {
  final List<Token> tokens;
  int _pos = 0;

  Parser(this.tokens);

  factory Parser.forFormula(String body) {
    try {
      return Parser(Lexer(body).tokenize());
    } on LexException catch (error) {
      throw FormulaException(error.message);
    }
  }

  Expr parse() {
    final expr = _comparison();
    if (_peek().type != TokenType.eof) {
      throw FormulaException('Unexpected token "${_peek().lexeme}"');
    }
    return expr;
  }

  Expr _comparison() {
    var left = _concat();
    while (_matchAny(const [
      TokenType.eq,
      TokenType.neq,
      TokenType.lt,
      TokenType.lte,
      TokenType.gt,
      TokenType.gte,
    ])) {
      final op = _previous().lexeme;
      final right = _concat();
      left = BinaryOp(op, left, right);
    }
    return left;
  }

  Expr _concat() {
    var left = _additive();
    while (_matchAny(const [TokenType.amp])) {
      final right = _additive();
      left = BinaryOp('&', left, right);
    }
    return left;
  }

  Expr _additive() {
    var left = _multiplicative();
    while (_matchAny(const [TokenType.plus, TokenType.minus])) {
      final op = _previous().lexeme;
      final right = _multiplicative();
      left = BinaryOp(op, left, right);
    }
    return left;
  }

  Expr _multiplicative() {
    var left = _unary();
    while (_matchAny(const [TokenType.star, TokenType.slash, TokenType.percent])) {
      final op = _previous().lexeme;
      final right = _unary();
      left = BinaryOp(op, left, right);
    }
    return left;
  }

  Expr _unary() {
    if (_matchAny(const [TokenType.minus, TokenType.plus])) {
      final op = _previous().lexeme;
      return UnaryOp(op, _unary());
    }
    return _power();
  }

  Expr _power() {
    final base = _primary();
    if (_matchAny(const [TokenType.caret])) {
      final exponent = _unary();
      return BinaryOp('^', base, exponent);
    }
    return base;
  }

  Expr _primary() {
    final token = _peek();
    switch (token.type) {
      case TokenType.number:
        _advance();
        return NumberLit(token.numberValue);
      case TokenType.text:
        _advance();
        return TextLit(token.textValue);
      case TokenType.errorLit:
        _advance();
        return ErrorLit(token.errorKind);
      case TokenType.lparen:
        _advance();
        final expr = _comparison();
        _expect(TokenType.rparen, ')');
        return expr;
      case TokenType.cellRef:
        _advance();
        return _reference(token.lexeme, null);
      case TokenType.quotedName:
        _advance();
        _expect(TokenType.bang, '!');
        final ref = _expect(TokenType.cellRef, 'cell reference');
        return _reference(ref.lexeme, token.textValue);
      case TokenType.identifier:
        _advance();
        if (_peek().type == TokenType.lparen) {
          return FuncCall(token.lexeme, _argumentList());
        }
        if (_peek().type == TokenType.bang) {
          _advance();
          final ref = _expect(TokenType.cellRef, 'cell reference');
          return _reference(ref.lexeme, token.lexeme);
        }
        final upper = token.lexeme.toUpperCase();
        if (upper == 'TRUE') return const BoolLit(true);
        if (upper == 'FALSE') return const BoolLit(false);
        return NameNode(token.lexeme);
      default:
        throw FormulaException('Unexpected token "${token.lexeme}"');
    }
  }

  Expr _reference(String startLexeme, String? sheet) {
    final start = CellAddress.parse(startLexeme);
    if (_matchAny(const [TokenType.colon])) {
      final endToken = _expect(TokenType.cellRef, 'cell reference');
      return RangeNode(start, CellAddress.parse(endToken.lexeme), sheet);
    }
    return RefNode(start, sheet);
  }

  List<Expr> _argumentList() {
    _expect(TokenType.lparen, '(');
    final args = <Expr>[];
    if (_peek().type != TokenType.rparen) {
      args.add(_comparison());
      while (_matchAny(const [TokenType.comma])) {
        args.add(_comparison());
      }
    }
    _expect(TokenType.rparen, ')');
    return args;
  }

  bool _matchAny(List<TokenType> types) {
    if (types.contains(_peek().type)) {
      _advance();
      return true;
    }
    return false;
  }

  Token _expect(TokenType type, String label) {
    if (_peek().type != type) {
      throw FormulaException('Expected "$label" but found "${_peek().lexeme}"');
    }
    return _advance();
  }

  Token _peek() => tokens[_pos];

  Token _previous() => tokens[_pos - 1];

  Token _advance() => tokens[_pos++];
}
