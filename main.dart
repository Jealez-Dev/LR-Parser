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
    for (String line in content) {
      if (line.isEmpty) continue;

      int lineNumber = content.indexOf(line);
      int i = 0;
      while (i < line.length) {
        String letter = line[i];

        // 1. PROCESAR PALABRAS (Keywords e Identifiers)
        if (isLetter(letter)) {
          String word = '';
          while (i < line.length && isLetter(line[i])) {
            word += line[i];
            i++;
          }

          if (Token.keywords.contains(word)) {
            tokens.add(Token(['keyword'], word, lineNumber));
          } else {
            tokens.add(Token(['identifier'], word, lineNumber));
          }
          continue;
        }

        // 2. PROCESAR OPERADORES COMPUESTOS Y SIMPLES
        if (Token.operators.contains(letter)) {
          if (letter == '-' && i + 1 < line.length && line[i + 1] == '>') {
            tokens.add(Token(['operator'], '->', lineNumber));
            i += 2;
          } else if (letter == '>' &&
              i + 1 < line.length &&
              line[i + 1] == '=') {
            tokens.add(Token(['operator'], '>=', lineNumber));
            i += 2;
          } else if (letter == '<' &&
              i + 1 < line.length &&
              line[i + 1] == '=') {
            tokens.add(Token(['operator'], '<=', lineNumber));
            i += 2;
          } else {
            tokens.add(Token(['operator'], letter, lineNumber));
            i++;
          }
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

        // 4. PROCESAR ASIGNACION
        if (Token.Op_Assingnment.contains(letter)) {
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
    int numLinea = line.indexOf(line) + 1;
    return '\n❌ [Error Sintáctico]: Linea $numLinea: $line\n\n$message';
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

  static const Op_Assingnment = '=';

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
  ];

  static const List<String> charactersNotAllowed = [
    '@',
    '#',
    '\$',
    '%',
    '&',
    '"',
    "'",
    '!',
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
      print('${currentToken.value}');
      advance();
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

    if (currentToken.type.contains('separator') && currentToken.value == ';') {
      print('${currentToken.value}');
      advance();
      parseParForm();
    } else {
      return;
    }
  }

  void parseExp() {
    switch (currentToken.value) {
      case _ when currentToken.type.contains('constant'):
        print(currentToken.value);
        advance();
        return;

      case _ when currentToken.type.contains('identifier'):
        print(currentToken.value);
        advance();
        if (currentToken.type.contains('operator') &&
            currentToken.value != '->') {
          parseOper();
        }
        return;

      case _ when currentToken.type.contains('keyword'):
        if (currentToken.value == 'sea') {
          print(currentToken.value);
          advance();
          parseDecLoc();
        }

        if (currentToken.value == 'caso') {
          print(currentToken.value);
          advance();
          parseCondic();
        }
        return;

      case _
          when currentToken.type.contains('delimiter') &&
              currentToken.value == '(':
        print(currentToken.value);
        advance();
        parseExp();
        if (currentToken.type.contains('separator') &&
            currentToken.value == ',') {
          print(currentToken.value);
          advance();
          parseTuple();
        }
        if (currentToken.value == ')') {
          print(currentToken.value);
          advance();
        }
        return;

      default:
        throw SyntaxError(
          'Token no esperado: ${currentToken.value}',
          lines[currentToken.line],
          currentToken.value,
        );
    }
  }

  void parseDecLoc() {
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

    if (currentToken.type.contains('operator_assingnment') &&
        currentToken.value == '=') {
      print(currentToken.value);
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
      print(currentToken.value);
      advance();
      parseDecLoc();
    }

    if (currentToken.type.contains('keyword') && currentToken.value == 'en') {
      print(currentToken.value);
      advance();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    parseExp();
  }

  void parseCondic() {
    parseExp();

    if (currentToken.type.contains('operator') && currentToken.value == '->') {
      print(currentToken.value);
      advance();
      parseExp();
    } else {
      throw SyntaxError(
        'Token no esperado: ${currentToken.value}',
        lines[currentToken.line],
        currentToken.value,
      );
    }

    if (currentToken.type.contains('separator') && currentToken.value == '[]') {
      print(currentToken.value);
      advance();
      parseCondic();
    }

    if (currentToken.type.contains('keyword') &&
        currentToken.value == 'fcaso') {
      print(currentToken.value);
      advance();
      return;
    }
  }

  void parseTuple() {
    parseExp();
    if (currentToken.type.contains('separator') && currentToken.value == ',') {
      print(currentToken.value);
      advance();
      parseTuple();
    } else {
      return;
    }
  }

  void parseOper() {
    if (currentToken.type.contains('operator')) {
      print(currentToken.value);
      advance();
      parseExp();
    }
  }

  void parseTerm(List<Token> tokens) {}

  void parseFactor(List<Token> tokens) {}

  void parseConst(List<Token> tokens) {}

  void parseId(List<Token> tokens) {}
}
