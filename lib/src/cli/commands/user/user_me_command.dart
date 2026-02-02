import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// View the authenticated user's profile.
///
/// ```
/// x user me [--json]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class UserMeCommand extends Command<int> {
  UserMeCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON response.',
    );
  }

  @override
  String get name => 'me';

  @override
  String get description => 'View your own profile.';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final jsonOutput = argResults!['json'] as bool;

    final response = await _api.getMe();

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
      print('Could not retrieve profile.');
      return;
    }

    // ignore: avoid_print
    print(formatUserLine(data));
  }
}
