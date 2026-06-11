import 'dart:io';

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
          String separators = '';
          while (i < line.length && Token.separators.contains(line[i])) {
            separators += line[i];
            i++;
            if (i < line.length && line[i] == '.') {
              separators += line[i];
              i++;
            }
          }
          tokens.add(Token(['separator'], separators, lineNumber));
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
    return tokens;
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

  static const List<String> separators = [',', '.', ':', ';', '[]'];

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

  static const List<String> delimiters = ['(', ')', '[', ']'];

  final List<String> type;
  final String value;
  final int line;
  Token(this.type, this.value, this.line);

  String toString() {
    return 'Linea: $line, Type: $type, Value: $value';
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
