import 'dart:convert';
import 'dart:io';

import 'package:alexandria/src/doc_generator.dart';

Future<void> main(List<String> args) async {
  final configFile = File('alexandria_config.json');
  if (!configFile.existsSync()) {
    print('Error: alexandria_config.json not found in the current directory.');
    exit(1);
  }

  try {
    final configString = await configFile.readAsString();
    final List<dynamic> config = jsonDecode(configString);

    if (config.isEmpty) {
      print('Error: alexandria_config.json is empty or invalid.');
      exit(1);
    }

    final docGenerator = DocGenerator(config);
    await docGenerator.generate();
  } catch (e) {
    print('An error occurred: $e');
    exit(1);
  }
}
