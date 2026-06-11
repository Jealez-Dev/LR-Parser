import 'Lexer.dart';
import 'Parser.dart';

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
    print('Not yet implemented, please use --help for more information.');
  }

  if (args.contains('--version')) {
    print('LR Parser v0.0.1');
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
