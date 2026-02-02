import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// View tweets mentioning you.
///
/// ```
/// x timeline mentions [--json]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class TimelineMentionsCommand extends Command<int> {
  TimelineMentionsCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON response.',
    );
  }

  @override
  String get name => 'mentions';

  @override
  String get description => 'View tweets mentioning you.';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final jsonOutput = argResults!['json'] as bool;

    final response = await _api.mentions();

    if (jsonOutput) {
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(response));
      return 0;
    }

    _printTweetList(response);
    return 0;
  }

  void _printTweetList(Map<String, dynamic> response) {
    final data = response['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      // ignore: avoid_print
      print('No mentions found.');
      return;
    }

    final includes = response['includes'] as Map<String, dynamic>?;
    final buf = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      if (i > 0) {
        buf.writeln();
        buf.writeln(dim('---'));
        buf.writeln();
      }
      final tweet = data[i] as Map<String, dynamic>;
      buf.writeln(formatTweetLine(tweet, showId: true, includes: includes));
    }

    // ignore: avoid_print
    print(buf.toString().trimRight());
  }
}
