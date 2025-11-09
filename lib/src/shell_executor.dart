import 'dart:io';

class ShellExecutor {
  Future<ProcessResult> execute(String command, List<String> arguments, {String? workingDirectory}) async {
    final result = await Process.run(command, arguments, workingDirectory: workingDirectory);
    return result;
  }
}
