import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'shell_executor.dart';

class DocGenerator {
  final Map<String, dynamic> _config;
  final _shell = ShellExecutor();

  DocGenerator(List<dynamic> config) : _config = config.first;

  Future<void> generate() async {
    final outputDir = _expandPath(_config['output_dir']);
    final projectsRoot = _expandPath(_config['projects_root']);
    final projects = _config['projects'] as List<dynamic>;
    final projectNames = <String>[];

    print('Output directory set to: $outputDir');
    print('Projects root set to: $projectsRoot');

    for (final project in projects) {
      final projectPath = p.join(projectsRoot, project);
      final projectName = p.basename(projectPath);
      projectNames.add(projectName);
      final projectOutputDir = p.join(outputDir, projectName);

      print('\n--- Checking project: $projectName ---');
      
      final currentVersion = await _getProjectVersion(projectPath);
      if (currentVersion == null) {
        print('ERROR: Could not determine version for $projectName. Skipping.');
        continue;
      }

      final metadataFile = File(p.join(projectOutputDir, 'alexandria_metadata.json'));
      if (metadataFile.existsSync()) {
        final metadata = jsonDecode(await metadataFile.readAsString());
        final generatedVersion = metadata['version'];
        if (generatedVersion == currentVersion) {
          print('Version $currentVersion is already generated. Skipping.');
          continue;
        }
        print('New version detected ($currentVersion). Generating docs...');
      } else {
        print('No previous documentation found. Generating docs...');
      }

      await Directory(projectOutputDir).create(recursive: true);

      final result = await _shell.execute(
        'dart',
        ['doc', '--output', projectOutputDir],
        workingDirectory: projectPath,
      );

      if (result.exitCode == 0) {
        await metadataFile.writeAsString('{"version": "$currentVersion"}');
        print('Successfully generated docs for $projectName.');
        if (result.stdout.toString().isNotEmpty) {
          print(result.stdout);
        }
      } else {
        print('ERROR: Failed to generate docs for $projectName.');
        print('Exit Code: ${result.exitCode}');
        if (result.stderr.toString().isNotEmpty) {
          print(result.stderr);
        }
      }
    }
    
    await _createIndexPage(outputDir, projectNames);
    print('\n--- All projects processed. ---');
  }

  Future<String?> _getProjectVersion(String projectPath) async {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      return null;
    }
    final content = await pubspecFile.readAsString();
    final match = RegExp(r'^version:\s*(.*)$', multiLine: true).firstMatch(content);
    return match?.group(1)?.trim();
  }

  Future<void> _createIndexPage(String outputDir, List<String> projectNames) async {
    print('\n--- Creating master index page ---');
    final indexPath = p.join(outputDir, 'index.html');
    
    final projectsListHtml = projectNames.map((name) => '''
      <li><a href="$name/index.html">$name</a></li>
    ''').join('\n');

    final htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            font-size: 16px;
            line-height: 1.5;
            color: #08213c;
            background-color: #f5f7f9;
            margin: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            width: 90%;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        header {
            background-color: #1c3c59;
            color: white;
            padding: 2rem;
            text-align: center;
        }
        h1 {
            font-size: 2.5rem;
            margin: 0;
            font-weight: 600;
        }
        main {
            padding: 2rem;
        }
        h2 {
            font-size: 1.5rem;
            color: #1c3c59;
            border-bottom: 2px solid #e0e5e9;
            padding-bottom: 0.5rem;
            margin-top: 0;
        }
        ul {
            list-style: none;
            padding: 0;
        }
        li {
            margin-bottom: 0.5rem;
        }
        a {
            display: block;
            padding: 0.75rem 1.5rem;
            text-decoration: none;
            color: #01579b;
            font-size: 1.1rem;
            font-weight: 500;
            background-color: #f5f7f9;
            border-radius: 4px;
            transition: background-color 0.2s ease, transform 0.2s ease;
        }
        a:hover {
            background-color: #eef2f5;
            transform: translateX(4px);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Project Documentation</h1>
        </header>
        <main>
            <h2>Available Projects</h2>
            <ul>
                $projectsListHtml
            </ul>
        </main>
    </div>
</body>
</html>
''';

    try {
      await File(indexPath).writeAsString(htmlContent);
      print('Successfully created index page at: $indexPath');
    } catch (e) {
      print('ERROR: Failed to create index page: $e');
    }
  }

  String _expandPath(String path) {
    if (path.startsWith('~/')) {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null) {
        return p.join(home, path.substring(2));
      }
    }
    return path;
  }
}
