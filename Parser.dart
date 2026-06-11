import 'Lexer.dart';

class Parser {
  final List<Token> tokens;
  final List<String> lines;
  int i = 0;

  Parser(this.tokens, this.lines);

  Token get currentToken => i < tokens.length ? tokens[i] : Token([], '', 0);

  void advance() {
    if (i < tokens.length) {
      i++;
    }
  }

  void parseProg() {
    // Comienza el analisis sintactico
    if (currentToken.value == 'fun') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('identifier')) {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == '(') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    parseParForm();

    if (currentToken.value == ')') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == 'dev') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == '(') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    parseParForm();

    if (currentToken.value == ')') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('operator_assingnment') &&
        currentToken.value == '=') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    parseExp();

    if (currentToken.value == 'ffun') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    // Si el siguiente token es 'fun', parseamos otra función.
    // Si no hay más tokens (cadena vacía), el análisis termina correctamente.
    if (currentToken.value == 'fun') {
      parseProg();
    } else if (currentToken.value != '') {
      throw SyntaxError(
        'Se esperaba "fun" o el fin del archivo',
        lines[currentToken.line],
        currentToken.value,
      );
    }
  }

  void parseParForm() {
    if (currentToken.type.contains('identifier')) {
      parseParArg();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('separator') && currentToken.value == ':') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('dataType')) {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('separator') && currentToken.value == ';') {
      advance();
      parseParForm();
    } else {
      return;
    }
  }

  void parseExp() {
    parseRelaction();
    return;
  }

  void parseRelaction() {
    parseTerm();

    final relOps = ['>', '<', '>=', '<=', '==', '!='];
    while (currentToken.type.contains('operator') &&
        relOps.contains(currentToken.value)) {
      advance();
      parseTerm();
    }
  }

  void parseTerm() {
    parseProduct();

    while (currentToken.type.contains('operator') &&
        (currentToken.value == '+' || currentToken.value == '-')) {
      advance();
      parseProduct();
    }
  }

  void parseProduct() {
    parsePower();

    while (currentToken.type.contains('operator') &&
        (currentToken.value == '*' ||
            currentToken.value == '/' ||
            currentToken.value == '%')) {
      advance();
      parsePower();
    }
  }

  void parsePower() {
    parseFactor();

    if (currentToken.type.contains('operator') && currentToken.value == '^') {
      advance();
      parsePower();
    }

    return;
  }

  void parseFactor() {
    final token = currentToken;

    // Operador unario ¬: ahora tiene la precedencia más alta
    if (token.type.contains('operator') && token.value == '¬') {
      advance();
      parseFactor(); // Llamada recursiva para permitir ¬¬a
      return;
    }

    if (token.type.contains('constant')) {
      parseConst();
    } else if (token.type.contains('keyword') && token.value == 'caso') {
      parseCase();
    } else if (token.type.contains('keyword') && token.value == 'sea') {
      parseDecLocal();
    } else if (token.type.contains('identifier')) {
      parseIDOrFunctionOrVector();
    } else if (token.value == '(') {
      parseTupleOrAgroup();
    } else {
      throw SyntaxError(
        'Se esperaba una constante, "sea", "caso", un identificador o "(", pero se encontró: ${token.value}',
        lines[token.line],
        token.value,
      );
    }
  }

  void parseConst() {
    if (currentToken.type.contains('constant')) {
      advance();
    }
    return;
  }

  parseDecLocal() {
    if (currentToken.type.contains('keyword') && currentToken.value == 'sea') {
      advance();
      parseDecLocalDef();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    if (currentToken.type.contains('keyword') && currentToken.value == 'en') {
      advance();
      parseExp();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    return;
  }

  void parseDecLocalDef() {
    if (currentToken.type.contains('identifier')) {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('operator_assingnment') &&
        currentToken.value == '=') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    parseExp();

    if (currentToken.type.contains('separator') && currentToken.value == ',') {
      advance();
      parseDecLocalDef();
    }

    return;
  }

  void parseCase() {
    if (currentToken.type.contains('keyword') && currentToken.value == 'caso') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    parseDefCase();
    if (currentToken.type.contains('keyword') &&
        currentToken.value == 'fcaso') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    return;
  }

  void parseDefCase() {
    parseExp();
    if (currentToken.type.contains('operator') && currentToken.value == '->') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == '[]') {
      advance();
      parseDefCase();
    }
    return;
  }

  void parseIDOrFunctionOrVector() {
    if (currentToken.type.contains('identifier')) {
      advance();

      // Bucle para manejar f(x)[i] o c[i][j]
      while (true) {
        if (currentToken.value == '(') {
          advance();
          if (currentToken.value != ')') {
            parseParArg();
          }
          if (currentToken.value == ')') {
            advance();
          } else {
            throw SyntaxError(
              'Se esperaba ")" al cerrar parámetros',
              lines[currentToken.line],
              currentToken.value,
            );
          }
        } else if (currentToken.value == '[') {
          advance();
          parseExp();
          if (currentToken.value == ']') {
            advance();
          } else {
            throw SyntaxError(
              'Se esperaba "]" al cerrar índice',
              lines[currentToken.line],
              currentToken.value,
            );
          }
        } else {
          break;
        }
      }
    } else {
      throw SyntaxError(
        'Se esperaba un identificador',
        lines[currentToken.line],
        currentToken.value,
      );
    }
  }

  void parseParArg() {
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == ',') {
      advance();
      parseParArg();
    }
    return;
  }

  void parseTupleOrAgroup() {
    if (currentToken.type.contains('delimiter') && currentToken.value == '(') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value} se esperaba un parentesis de apertura "("',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    parseParTuple();
    if (currentToken.type.contains('delimiter') && currentToken.value == ')') {
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}, se esperaba un parentesis de cierre ")"',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    return;
  }

  void parseParTuple() {
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == ',') {
      advance();
      parseParTuple();
    }
    return;
  }
}

class SyntaxError implements Exception {
  final String message;
  final String line;
  final String character;

  SyntaxError(this.message, this.line, this.character);

  @override
  String toString() {
    return '\n❌ [Error Sintáctico]: $line\n\n$message';
  }
}
