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
      file.read();
      List<Token> tokens = file.extractTokens();
      print(tokens.join('\n'));
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

  void read() {
    if (file.existsSync() && file.path.endsWith('.esp')) {
      content.addAll(file.readAsLinesSync());
    } else {
      print('File not found');
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

      int lineNumber = content.indexOf(line) + 1;
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
          } else {
            tokens.add(Token(['operator'], letter, lineNumber));
            i++;
          }
          continue;
        }

        // 3. PROCESAR SEPARADORES
        if (Token.separators.contains(letter)) {
          tokens.add(Token(['separator'], letter, lineNumber));
          i++;
          continue;
        }

        // 4. PROCESAR DELIMITADORES
        if (Token.delimiters.contains(letter)) {
          tokens.add(Token(['delimiter'], letter, lineNumber));
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

  static const List<String> separators = [
    ',',
    '.',
    ' ',
    ':',
    ';',
    '\n',
    '\t',
    '\r',
    '\f',
  ];

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
