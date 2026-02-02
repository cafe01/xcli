import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// View a user profile by username.
///
/// ```
/// x user view <username> [--json]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class UserViewCommand extends Command<int> {
  UserViewCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON response.',
    );
  }

  @override
  String get name => 'view';

  @override
  String get description => 'View a user profile.';

  @override
  String get invocation => 'x user view <username>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <username>');
    }
    final username = args.first;
    final jsonOutput = argResults!['json'] as bool;

    final response = await _api.getUser(username);

    if (jsonOutput) {
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(response));
      return 0;
    }

    _printHumanReadable(response);
    return 0;
  }

  void _printHumanReadable(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      // ignore: avoid_print
      print('User not found.');
      return;
    }

    // ignore: avoid_print
    print(formatUserLine(data));
  }
}
