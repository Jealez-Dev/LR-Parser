import 'dart:io';
import 'Lexer.dart';
import 'Parser.dart';

// Profesor, no hubo presupuesto para hacer el IDE, pero lo hice para probar el parser
// Flutter si existe en linux, pero no lo pude instalar en Fedora JAJAJAJAJAJA
// Y como no quise hacerlo en Flutter (Perder mi tiempo haciendo que flutter agarre), lo hice en Dart puro :D

// PD: Este IDE no carga archivos .esp, solo los crea, pero si funciona para probar el parser

void IDE() {
  if (!stdin.hasTerminal) {
    print('Este programa solo funciona en la consola interactiva.');
    exit(1);
  }

  stdout.write('Introduzca el nombre del archivo (con extensión .esp): ');
  String? fileName = stdin.readLineSync()?.trim();

  if (fileName == null || fileName.isEmpty) {
    print('Por favor, introduzca un nombre de archivo .esp.');
    exit(1);
  }

  final archivo = File(fileName);
  List<String> lines = [];

  if (archivo.existsSync()) {
    lines = archivo.readAsLinesSync();
  }
  if (lines.isEmpty) {
    lines.add('');
  }

  final originalEchoMode = stdin.echoMode;
  final originalLineMode = stdin.lineMode;

  int cursorX = 0;
  int cursorY = 0;
  bool running = true;

  void refreshScreen() {
    // Limpiar pantalla y mover cursor al inicio
    stdout.write('\x1b[2J\x1b[H');

    // Dibujar encabezado
    stdout.write('\x1b[7m LR Parser IDE - Editando: $fileName \x1b[0m\n');

    // Dibujar líneas de texto
    for (int i = 0; i < lines.length; i++) {
      stdout.write('${lines[i]}\n');
    }

    // Dibujar barra de estado inferior
    int terminalHeight = stdout.terminalLines;
    stdout.write('\x1b[${terminalHeight - 1};1H');
    stdout.write(
      '\x1b[7m Ctrl+X: Salir | Ctrl+O: Guardar | Ctrl+A: Guardar y Analizar | Línea: ${cursorY + 1} Col: ${cursorX + 1} \x1b[0m',
    );

    // Posicionar el cursor real (ANSI usa 1-based indexing)
    // Sumamos 2 a Y porque el encabezado ocupa la línea 1
    stdout.write('\x1b[${cursorY + 2};${cursorX + 1}H');
  }

  try {
    stdin.echoMode = false;
    stdin.lineMode = false;

    while (running) {
      refreshScreen();
      final int charCode = stdin.readByteSync();

      // Control de salida (Ctrl+X = 24)
      if (charCode == 24) {
        running = false;
      }
      // Control de guardado (Ctrl+O = 15)
      else if (charCode == 15) {
        archivo.writeAsStringSync(lines.join('\n'));
        // Feedback temporal
        stdout.write(
          '\x1b[${stdout.terminalLines};1H\x1b[32mGuardado con éxito!\x1b[0m',
        );
        sleep(Duration(milliseconds: 500));
      }
      // Control de guardado y análisis (Ctrl+A = 1)
      else if (charCode == 1) {
        archivo.writeAsStringSync(lines.join('\n'));

        try {
          // Ejecutar el análisis directamente usando las clases del proyecto
          ReaderFile reader = ReaderFile(fileName);
          // Leemos el contenido que acabamos de guardar
          List<String> content = reader.read();
          List<Token> tokens = reader.extractTokens();
          Parser parser = Parser(tokens, content);

          parser.parseProg();

          stdout.write(
            '\x1b[${stdout.terminalLines};1H\x1b[32m✓ Guardado y Análisis OK\x1b[0m',
          );
        } catch (e) {
          // Si hay un error léxico o sintáctico, lo mostramos en la barra de estado
          String errorMsg = e.toString().replaceAll('\n', ' ').trim();
          int maxLen = stdout.terminalColumns - 5;
          if (errorMsg.length > maxLen)
            errorMsg = errorMsg.substring(0, maxLen) + "...";
          stdout.write(
            '\x1b[${stdout.terminalLines};1H\x1b[31m✗ Error: $errorMsg\x1b[0m',
          );
        }
        sleep(Duration(seconds: 5));
      }
      // Backspace (127 o 8)
      else if (charCode == 127 || charCode == 8) {
        if (cursorX > 0) {
          String line = lines[cursorY];
          lines[cursorY] =
              line.substring(0, cursorX - 1) + line.substring(cursorX);
          cursorX--;
        } else if (cursorY > 0) {
          cursorX = lines[cursorY - 1].length;
          lines[cursorY - 1] += lines[cursorY];
          lines.removeAt(cursorY);
          cursorY--;
        }
      }
      // Enter (13 o 10)
      else if (charCode == 13 || charCode == 10) {
        String currentLine = lines[cursorY];
        String firstPart = currentLine.substring(0, cursorX);
        String secondPart = currentLine.substring(cursorX);
        lines[cursorY] = firstPart;
        lines.insert(cursorY + 1, secondPart);
        cursorY++;
        cursorX = 0;
      }
      // Tabulación (9)
      else if (charCode == 9) {
        lines[cursorY] =
            lines[cursorY].substring(0, cursorX) +
            "  " +
            lines[cursorY].substring(cursorX);
        cursorX += 2;
      }
      // Secuencias de escape (Flechas de dirección)
      else if (charCode == 27) {
        final next1 = stdin.readByteSync();
        if (next1 == 91) {
          // '['
          final next2 = stdin.readByteSync();
          switch (next2) {
            case 65: // Arriba
              if (cursorY > 0) {
                cursorY--;
                if (cursorX > lines[cursorY].length)
                  cursorX = lines[cursorY].length;
              }
              break;
            case 66: // Abajo
              if (cursorY < lines.length - 1) {
                cursorY++;
                if (cursorX > lines[cursorY].length)
                  cursorX = lines[cursorY].length;
              }
              break;
            case 67: // Derecha
              if (cursorX < lines[cursorY].length) {
                cursorX++;
              } else if (cursorY < lines.length - 1) {
                cursorY++;
                cursorX = 0;
              }
              break;
            case 68: // Izquierda
              if (cursorX > 0) {
                cursorX--;
              } else if (cursorY > 0) {
                cursorY--;
                cursorX = lines[cursorY].length;
              }
              break;
          }
        }
      }
      // Caracteres imprimibles
      else if (charCode >= 32) {
        String char = String.fromCharCode(charCode);
        String line = lines[cursorY];
        lines[cursorY] =
            line.substring(0, cursorX) + char + line.substring(cursorX);
        cursorX++;
      }
    }
  } catch (e) {
    print('\x1b[2J\x1b[H Error en el IDE: $e');
  } finally {
    // Restaurar terminal y limpiar pantalla al salir
    stdin.echoMode = originalEchoMode;
    stdin.lineMode = originalLineMode;
    stdout.write('\x1b[2J\x1b[H');
    print('Sesión de edición finalizada para: $fileName');
  }
}
