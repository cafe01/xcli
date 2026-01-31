import 'dart:io';

import 'package:xcli/src/cli/x_runner.dart';

Future<void> main(List<String> args) async {
  final runner = XCommandRunner();
  final exitCode = await runner.run(args);
  exit(exitCode ?? 0);
}
