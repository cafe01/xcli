import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// Search recent tweets.
///
/// ```
/// x search tweets <query> [--json]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class SearchTweetsCommand extends Command<int> {
  SearchTweetsCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output raw JSON response.',
    );
  }

  @override
  String get name => 'tweets';

  @override
  String get description => 'Search recent tweets.';

  @override
  String get invocation => 'x search tweets <query>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <query>');
    }
    final query = args.join(' ');
    final jsonOutput = argResults!['json'] as bool;

    final response = await _api.searchTweets(query);

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

    // Result count header.
    buf.writeln(dim('${data.length} result${data.length == 1 ? '' : 's'}'));
    buf.writeln();

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
