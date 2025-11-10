import 'dart:convert';
import 'dart:io';

import 'package:alexandria/src/doc_generator.dart';
import 'package:args/args.dart';

const version = '1.0.5';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to the alexandria_config.json file.',
      defaultsTo: 'alexandria_config.json',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Displays this help information.',
    )
    ..addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Displays the application version.',
    )
    ..addFlag(
      'quiet',
      abbr: 'q',
      negatable: false,
      help: 'Suppresses output from dart doc.',
    );

  final argResults = parser.parse(args);

  if (argResults['help']) {
    print('Alexandria v$version\n');
    print(parser.usage);
    exit(0);
  }

  if (argResults['version']) {
    print('Alexandria v$version');
    exit(0);
  }

  final configFile = File(argResults['config']);
  if (!configFile.existsSync()) {
    print('Error: Config file not found at ${configFile.path}');
    exit(1);
  }

  try {
    final configString = await configFile.readAsString();
    final List<dynamic> config = jsonDecode(configString);

    if (config.isEmpty) {
      print('Error: alexandria_config.json is empty or invalid.');
      exit(1);
    }

    final docGenerator = DocGenerator(
      config,
      quiet: argResults['quiet'],
    );
    await docGenerator.generate();
  } catch (e, stack) {
    print('ERROR: Failed to generate docs.');
    print('Exception: $e');
    print('Stack Trace: $stack');
    exit(1);
  }
}
