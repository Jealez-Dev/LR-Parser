import 'dart:io';
import 'dart:convert';

void main() {
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
  final originalEchoMode = stdin.echoMode;
  final originalLineMode = stdin.lineMode;

  List<int> buffer = [];

  try {
    stdin.echoMode = false;
    stdin.lineMode = false;

    stdout.write('--- LR Parser ---\n\n');

    while (true) {
      final chunk = stdin.readByteSync();

      if (chunk == 24) {
        break;
      }

      if (chunk == 13 || chunk == 10) {
        buffer.add(10);
        stdout.write('\n');
        continue;
      }

      if (chunk == 9) {
        buffer.add(9);
        stdout.write('   ');
        continue;
      }

      if (chunk == 15) {
        try {
          // Convertimos los bytes acumulados a String y los guardamos
          String contenido = String.fromCharCodes(buffer);
          archivo.writeAsStringSync(contenido);

          // Feedback visual rápido de guardado en la barra inferior
          stdout.write(
            '\n\n[✓ Archivo guardado con éxito] Reimprimiendo...\n\n',
          );
          // Re-imprimir el búfer actual para mantener la consistencia visual
          stdout.write(contenido);
        } catch (e) {
          stdout.write('\n\n[Error al guardar: $e]\n\n');
        }
        continue;
      }

      // Control 4: Borrar / Backspace (ASCII 8 o 127)
      if (chunk == 8 || chunk == 127) {
        if (buffer.isNotEmpty) {
          int ultimo = buffer.removeLast();

          if (ultimo != 10) {
            stdout.write('\b \b');
          }
        }
        continue;
      }

      buffer.add(chunk);
      stdout.write(String.fromCharCode(chunk));
    }
  } finally {
    stdin.echoMode = originalEchoMode;
    stdin.lineMode = originalLineMode;
    print('Tu entrada fue: \n$buffer');
  }
}
