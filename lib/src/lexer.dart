import 'tokens.dart';
import 'values.dart';

class LexException implements Exception {
  final String message;
  const LexException(this.message);

  @override
  String toString() => 'LexException: $message';
}

class Lexer {
  final String source;
  int _pos = 0;

  Lexer(this.source);

  List<Token> tokenize() {
    final tokens = <Token>[];
    while (!_atEnd) {
      final ch = _peek();
      if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
        _pos++;
        continue;
      }
      if (ch == '#') {
        tokens.add(_readErrorLiteral());
        continue;
      }
      if (_isDigit(ch) || (ch == '.' && _isDigit(_peekAt(1)))) {
        tokens.add(_readNumber());
        continue;
      }
      if (ch == '"') {
        tokens.add(_readText());
        continue;
      }
      if (ch == "'") {
        tokens.add(_readQuotedName());
        continue;
      }
      if (ch == r'$' || _isLetter(ch)) {
        tokens.add(_readWord());
        continue;
      }
      tokens.add(_readOperator());
    }
    tokens.add(const Token(TokenType.eof, ''));
    return tokens;
  }

  Token _readErrorLiteral() {
    for (final kind in ErrorKind.values) {
      if (source.startsWith(kind.symbol, _pos)) {
        _pos += kind.symbol.length;
        return Token(TokenType.errorLit, kind.symbol, kind);
      }
    }
    throw LexException('Unknown error literal at position $_pos');
  }

  Token _readNumber() {
    final start = _pos;
    while (!_atEnd && _isDigit(_peek())) {
      _pos++;
    }
    if (!_atEnd && _peek() == '.') {
      _pos++;
      while (!_atEnd && _isDigit(_peek())) {
        _pos++;
      }
    }
    final lexeme = source.substring(start, _pos);
    return Token(TokenType.number, lexeme, double.parse(lexeme));
  }

  Token _readText() {
    _pos++;
    final buffer = StringBuffer();
    while (!_atEnd) {
      final ch = _peek();
      if (ch == '"') {
        if (_peekAt(1) == '"') {
          buffer.write('"');
          _pos += 2;
          continue;
        }
        _pos++;
        return Token(TokenType.text, buffer.toString(), buffer.toString());
      }
      buffer.write(ch);
      _pos++;
    }
    throw const LexException('Unterminated string literal');
  }

  Token _readQuotedName() {
    _pos++;
    final buffer = StringBuffer();
    while (!_atEnd) {
      final ch = _peek();
      if (ch == "'") {
        if (_peekAt(1) == "'") {
          buffer.write("'");
          _pos += 2;
          continue;
        }
        _pos++;
        return Token(TokenType.quotedName, buffer.toString(), buffer.toString());
      }
      buffer.write(ch);
      _pos++;
    }
    throw const LexException('Unterminated sheet name');
  }

  Token _readWord() {
    final start = _pos;
    if (_peek() == r'$') _pos++;
    while (!_atEnd && _isLetter(_peek())) {
      _pos++;
    }
    final hasDollar = _peek() == r'$';
    final afterLetters = hasDollar ? _peekAt(1) : _peek();
    if (_isDigit(afterLetters)) {
      if (hasDollar) _pos++;
      while (!_atEnd && _isDigit(_peek())) {
        _pos++;
      }
      final lexeme = source.substring(start, _pos);
      if (_peek() == '!' || _peek() == '(') return Token(TokenType.identifier, lexeme);
      return Token(TokenType.cellRef, lexeme);
    }
    final lexeme = source.substring(start, _pos);
    return Token(TokenType.identifier, lexeme);
  }

  Token _readOperator() {
    final ch = _peek();
    switch (ch) {
      case '+':
        _pos++;
        return const Token(TokenType.plus, '+');
      case '-':
        _pos++;
        return const Token(TokenType.minus, '-');
      case '*':
        _pos++;
        return const Token(TokenType.star, '*');
      case '/':
        _pos++;
        return const Token(TokenType.slash, '/');
      case '^':
        _pos++;
        return const Token(TokenType.caret, '^');
      case '%':
        _pos++;
        return const Token(TokenType.percent, '%');
      case '&':
        _pos++;
        return const Token(TokenType.amp, '&');
      case '(':
        _pos++;
        return const Token(TokenType.lparen, '(');
      case ')':
        _pos++;
        return const Token(TokenType.rparen, ')');
      case ',':
        _pos++;
        return const Token(TokenType.comma, ',');
      case ':':
        _pos++;
        return const Token(TokenType.colon, ':');
      case '!':
        _pos++;
        return const Token(TokenType.bang, '!');
      case '=':
        _pos++;
        return const Token(TokenType.eq, '=');
      case '<':
        _pos++;
        if (_peek() == '=') {
          _pos++;
          return const Token(TokenType.lte, '<=');
        }
        if (_peek() == '>') {
          _pos++;
          return const Token(TokenType.neq, '<>');
        }
        return const Token(TokenType.lt, '<');
      case '>':
        _pos++;
        if (_peek() == '=') {
          _pos++;
          return const Token(TokenType.gte, '>=');
        }
        return const Token(TokenType.gt, '>');
      default:
        throw LexException('Unexpected character "$ch" at position $_pos');
    }
  }

  bool get _atEnd => _pos >= source.length;

  String _peek() => _atEnd ? '' : source[_pos];

  String _peekAt(int offset) {
    final index = _pos + offset;
    return index >= source.length ? '' : source[index];
  }

  bool _isDigit(String ch) => ch.length == 1 && ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;

  bool _isLetter(String ch) {
    if (ch.length != 1) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) || code == 0x5F;
  }
}
