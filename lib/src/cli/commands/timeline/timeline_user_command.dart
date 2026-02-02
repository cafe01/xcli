import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// View a user's timeline.
///
/// Accepts a username, resolves it to a user ID, and fetches their tweets.
///
/// ```
/// x timeline user <username> [--json]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class TimelineUserCommand extends Command<int> {
  TimelineUserCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON response.',
    );
  }

  @override
  String get name => 'user';

  @override
  String get description => "View a user's timeline.";

  @override
  String get invocation => 'x timeline user <username>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <username>');
    }
    final username = args.first;
    final jsonOutput = argResults!['json'] as bool;

    // Resolve username to user ID.
    final userResponse = await _api.getUser(username);
    final userData = userResponse['data'] as Map<String, dynamic>;
    final userId = userData['id'] as String;

    final response = await _api.userTimeline(userId);

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
      print('No tweets found.');
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
