import 'dart:convert';
import 'dart:io';

import 'package:alexandria/src/doc_generator.dart';
import 'package:args/args.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:path/path.dart' as p;

Future<String> _getPackageVersion() async {
  var scriptDir = p.dirname(Platform.script.toFilePath());
  var projectRoot = Directory(scriptDir);

  // In a compiled executable, the scriptDir might be in a bin/ or lib/ directory
  // relative to the project root. We need to go up until we find pubspec.yaml.
  while (projectRoot.parent.path != projectRoot.path) {
    final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      final pubspecContent = await pubspecFile.readAsString();
      final pubspec = Pubspec.parse(pubspecContent);
      return pubspec.version?.toString() ?? 'Unknown';
    }
    projectRoot = projectRoot.parent;
  }

  // Fallback for development environment (running from project root)
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = Pubspec.parse(pubspecContent);
    return pubspec.version?.toString() ?? 'Unknown';
  }

  return 'Unknown';
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to the alexandria_config.json file.',
      defaultsTo: 'alexandria_config.json',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Displays this help information.')
    ..addFlag('version', negatable: false, help: 'Displays the application version.')
    ..addFlag('verbose', abbr: 'o', negatable: false, help: 'Shows verbose output from dart doc.');

  final argResults = parser.parse(args);
  final version = await _getPackageVersion();

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

    final docGenerator = DocGenerator(config, verbose: argResults['verbose']);
    await docGenerator.generate();
  } catch (e, stack) {
    print('ERROR: Failed to generate docs.');
    print('Exception: $e');
    print('Stack Trace: $stack');
    exit(1);
  }
}
