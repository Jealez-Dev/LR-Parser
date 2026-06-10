import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: main.dart <file.esp>');
  }

  if (args.contains('--help')) {
    print('Commands:');
    print('  --help');
    print('  --ide');
    print('  --version');
    print('  --analyze <file.esp>');
    return;
  }

  if (args.contains('--ide')) {
    print('Not yet implemented, please use --help for more information.');
  }

  if (args.contains('--version')) {
    print('LR Parser v0.0.1');
  }

  if (args.contains('--analyze')) {
    print('Analizando ${args[1]}, por favor aguarde...');
    try {
      ReaderFile file = ReaderFile(args[1]);
      List<String> content = file.read();
      List<Token> tokens = file.extractTokens();
      Parser parser = Parser(tokens, content);
      parser.parseProg();
      print('Analisis OK');
    } catch (e) {
      print(e);
    }
  }
}

class ReaderFile {
  final File file;
  List<Token> tokens = [];
  List<String> content = [];
  ReaderFile(String path) : file = File(path);

  List<String> read() {
    if (file.existsSync() && file.path.endsWith('.esp')) {
      content.addAll(file.readAsLinesSync());
      return content;
    } else {
      print('File not found');
      exit(1);
    }
  }

  bool isLetter(String letter) {
    if (letter.isEmpty) return false;
    int codeUnit = letter.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }

  List<Token> extractTokens() {
    for (int lineNumber = 0; lineNumber < content.length; lineNumber++) {
      String line = content[lineNumber];

      int i = 0;
      while (i < line.length) {
        String letter = line[i];

        // 1. PROCESAR PALABRAS (Keywords, Identifiers y Tipos de Dato)
        if (isLetter(letter)) {
          String word = '';
          while (i < line.length && isLetter(line[i])) {
            word += line[i];
            i++;
          }

          if (word.contains('mod')) {
            throw LexicalError(
              'Caracter no permitido: ${word}, en este contexto, se usa % en vez de mod',
              line,
              i,
            );
          }

          if (Token.keywords.contains(word)) {
            tokens.add(Token(['keyword'], word, lineNumber));
          } else if (Token.dataTypes.contains(word)) {
            tokens.add(Token(['dataType'], word, lineNumber));
          } else if (Token.constants.contains(word)) {
            tokens.add(Token(['constant'], word, lineNumber));
          } else {
            tokens.add(Token(['identifier'], word, lineNumber));
          }
          continue;
        }

        // 2. PROCESAR OPERADORES (Compuestos y Simples)
        bool operatorMatched = true;
        if (letter == '-' && i + 1 < line.length && line[i + 1] == '>') {
          tokens.add(Token(['operator'], '->', lineNumber));
          i += 2;
        } else if (letter == '>' && i + 1 < line.length && line[i + 1] == '=') {
          tokens.add(Token(['operator'], '>=', lineNumber));
          i += 2;
        } else if (letter == '<' && i + 1 < line.length && line[i + 1] == '=') {
          tokens.add(Token(['operator'], '<=', lineNumber));
          i += 2;
        } else if (letter == '=' && i + 1 < line.length && line[i + 1] == '=') {
          tokens.add(Token(['operator'], '==', lineNumber));
          i += 2;
        } else if (letter == '!' && i + 1 < line.length && line[i + 1] == '=') {
          tokens.add(Token(['operator'], '!=', lineNumber));
          i += 2;
        } else if (Token.operators.contains(letter)) {
          tokens.add(Token(['operator'], letter, lineNumber));
          i++;
        } else {
          operatorMatched = false;
        }
        if (operatorMatched) continue;

        // 3. PROCESAR SEPARADORES (incluyendo [])
        if (letter == '[' && i + 1 < line.length && line[i + 1] == ']') {
          tokens.add(Token(['separator'], '[]', lineNumber));
          i += 2;
          continue;
        }

        // 3. PROCESAR SEPARADORES
        if (Token.separators.contains(letter)) {
          if (letter == '[' &&
              i + 1 < line.length &&
              Token.separators.contains(line[i + 1]) &&
              line[i + 1] == ']') {
            tokens.add(Token(['separator'], '[]', lineNumber));
            i += 2;
          } else {
            tokens.add(Token(['separator'], letter, lineNumber));
            i++;
          }
          continue;
        }

        // 4. PROCESAR DELIMITADORES
        if (Token.delimiters.contains(letter)) {
          tokens.add(Token(['delimiter'], letter, lineNumber));
          i++;
          continue;
        }

        // 5. PROCESAR ASIGNACION
        if (letter == Token.Op_Assingnment) {
          tokens.add(Token(['operator_assingnment'], letter, lineNumber));
          i++;
          continue;
        }

        // 5. PROCESAR CONSTANTES
        if (Token.constants.contains(letter)) {
          String constant = '';
          while (i < line.length && Token.constants.contains(line[i])) {
            constant += line[i];
            i++;
            if (i < line.length && line[i] == '.') {
              constant += line[i];
              i++;
            }
          }
          tokens.add(Token(['constant'], constant, lineNumber));
          continue;
        }

        if (Token.charactersNotAllowed.contains(letter)) {
          throw LexicalError('Caracter no permitido: $letter', line, i);
        }
        i++;
      }
    }
    print(tokens.join('\n'));
    return tokens;
  }
}

class LexicalError implements Exception {
  final String message;
  final String line;
  final int index;

  LexicalError(this.message, this.line, this.index);

  @override
  String toString() {
    String flecha = ' ' * index;
    return '\n❌ [Error Léxico]: $message\n\n$line\n$flecha^';
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

class Token {
  static const List<String> keywords = [
    'fun',
    'dev',
    'caso',
    'fcaso',
    'sea',
    'en',
    'ffun',
  ];

  static const List<String> separators = [',', '.', ':', ';', '[', ']'];

  static const List<String> dataTypes = ['int', 'float', 'string', 'bool'];

  static const List<String> constants = [
    'true',
    'false',
    'null',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const String Op_Assingnment = '=';

  static const List<String> operators = [
    '+',
    '-',
    '*',
    '/',
    '^',
    '<=',
    '>=',
    '>',
    '<',
    '->',
    '¬',
    '==',
    '!=',
    '%',
  ];

  static const List<String> charactersNotAllowed = [
    '@',
    '#',
    '\$',
    '%',
    '&',
    '"',
    "'",
    '?',
    '\\',
    '|',
    '_',
    '~',
    '`',
  ];

  static const List<String> delimiters = ['(', ')'];

  final List<String> type;
  final String value;
  final int line;
  Token(this.type, this.value, this.line);

  String toString() {
    return 'Linea: $line, Type: $type, Value: $value';
  }
}

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
      print('fun');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('identifier')) {
      print(currentToken.value);
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == '(') {
      print('(');
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
      print(')');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == 'dev') {
      print('dev');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.value == '(') {
      print('(');
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
      print(')');
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
      print('=');
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
      print('ffun');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
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
      print('${currentToken.value}');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('dataType')) {
      print('${currentToken.value}');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('separator') && currentToken.value == ';') {
      print('${currentToken.value}');
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
    if (currentToken.type.contains('operator') && currentToken.value == '¬') {
      print('${currentToken.value}');
      advance();
      parseTerm();
      return;
    }

    parseTerm();

    switch (currentToken.value) {
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '>':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '<':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '>=':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '<=':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;

      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '==':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;

      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '!=':
        print('${currentToken.value}');
        advance();
        parseTerm();
        break;

      default:
        return;
    }
  }

  void parseTerm() {
    parseProduct();

    switch (currentToken.value) {
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '+':
        print('${currentToken.value}');
        advance();
        parseProduct();
        break;
      case _
          when currentToken.type.contains('operator') &&
              currentToken.value == '-':
        print('${currentToken.value}');
        advance();
        parseProduct();
        break;
      default:
        return;
    }

    if (currentToken.type.contains('operator') && currentToken.value != '->') {
      print('${currentToken.value}');
      advance();
      parseRelaction();
    }
  }

  void parseProduct() {
    parsePower();

    if (currentToken.type.contains('operator')) {
      switch (currentToken.value) {
        case _
            when currentToken.type.contains('operator') &&
                currentToken.value == '*':
          print('${currentToken.value}');
          advance();
          parsePower();
          break;
        case _
            when currentToken.type.contains('operator') &&
                currentToken.value == '/':
          print('${currentToken.value}');
          advance();
          parsePower();
          break;
        case _
            when currentToken.type.contains('operator') &&
                currentToken.value == '%':
          print('${currentToken.value}');
          advance();
          parsePower();
          break;
        default:
          return;
      }
    }

    if (currentToken.type.contains('operator') && currentToken.value != '->') {
      print('${currentToken.value}');
      advance();
      parseRelaction();
    }
  }

  void parsePower() {
    parseFactor();

    if (currentToken.type.contains('operator') && currentToken.value == '^') {
      print('${currentToken.value}');
      advance();
      parseFactor();
    }

    if (currentToken.type.contains('operator') && currentToken.value != '->') {
      print('${currentToken.value}');
      advance();
      parseRelaction();
    }

    return;
  }

  void parseFactor() {
    final token = currentToken;
    if (token.type.contains('constant')) {
      parseConst();
    } else if (token.type.contains('keyword') && token.value == 'caso') {
      parseCase();
    } else if (token.type.contains('keyword') && token.value == 'sea') {
      parseDecLocal();
    } else if (token.type.contains('identifier')) {
      parseIDorFunction();
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
      print('${currentToken.value}');
      advance();
    }
    return;
  }

  parseDecLocal() {
    print('Comienzo de la declaracion');
    if (currentToken.type.contains('keyword') && currentToken.value == 'sea') {
      print('${currentToken.value}');
      advance();
      parseDecLocalDef();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    print('Mitad de la declaracion');
    if (currentToken.type.contains('keyword') && currentToken.value == 'en') {
      print('${currentToken.value}');
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
      print('${currentToken.value}');
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
      print('=');
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
      print('${currentToken.value}');
      advance();
      parseDecLocalDef();
    }

    return;
  }

  void parseCase() {
    if (currentToken.type.contains('keyword') && currentToken.value == 'caso') {
      print('${currentToken.value}');
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
      print('${currentToken.value}');
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
    print('Definicion de caso');
    parseExp();
    if (currentToken.type.contains('operator') && currentToken.value == '->') {
      print('${currentToken.value}');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    print('Fin o se encontro un repetidor de casos');
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == '[]') {
      print('${currentToken.value}');
      advance();
      parseDefCase();
    }
    return;
  }

  void parseIDorFunction() {
    print('Se encontro un identificador');
    if (currentToken.type.contains('identifier')) {
      print('${currentToken.value}');
      advance();
    }
    if (currentToken.type.contains('delimiter') && currentToken.value == '(') {
      print('Se encontro un parentesis de apertura, es decir, una funcion');
      print('${currentToken.value}');
      advance();
      parseParArg();
      if (currentToken.type.contains('delimiter') &&
          currentToken.value == ')') {
        print('${currentToken.value}');
        advance();
      }
    }
    return;
  }

  void parseParArg() {
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == ',') {
      print('${currentToken.value}');
      advance();
      parseParArg();
    }
    return;
  }

  void parseTupleOrAgroup() {
    print('Se encontro un parentesis de apertura');
    if (currentToken.type.contains('delimiter') && currentToken.value == '(') {
      print('${currentToken.value}');
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value} se esperaba un parentesis de apertura "("',
        lines[currentToken.line],
        currentToken.value,
      );
    }
    print('Contenido del parentesis');
    parseParTuple();
    print('Se encontro un parentesis de cierre');
    if (currentToken.type.contains('delimiter') && currentToken.value == ')') {
      print('${currentToken.value}');
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
      print('${currentToken.value}');
      advance();
      parseParTuple();
    }
    return;
  }
}
