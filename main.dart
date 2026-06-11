import 'Lexer.dart';
import 'Parser.dart';
import 'IDE.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: main.dart usa --help para obtener ayuda.');
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
    IDE();
  }

  if (args.contains('--version')) {
    print('LR Parser v1.1.0');
  }

  if (args.contains('--analyze')) {
    print('Analizando ${args[1]}, por favor aguarde...');
    try {
      final Stopwatch stopwatch = Stopwatch()..start();
      ReaderFile file = ReaderFile(args[1]);
      List<String> content = file.read();
      List<Token> tokens = file.extractTokens();
      Parser parser = Parser(tokens, content);
      parser.parseProg();
      print('Analisis OK');
      stopwatch.stop();
      print('Tiempo de ejecucion: ${stopwatch.elapsedMilliseconds} ms');
    } catch (e) {
      print(e);
    }
  }
}
