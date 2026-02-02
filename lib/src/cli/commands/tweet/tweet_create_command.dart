import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../format.dart';
import '../../x_runner.dart';

/// Create a new tweet.
///
/// ```
/// x tweet create <text> [--reply-to <id>] [--quote <id>] [--json]
/// ```
///
/// Default output is a confirmation with tweet ID and URL.
/// Use `--json` for the raw API response.
class TweetCreateCommand extends Command<int> {
  TweetCreateCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output raw JSON response.',
      )
      ..addOption(
        'reply-to',
        help: 'Tweet ID to reply to.',
        valueHelp: 'id',
      )
      ..addOption(
        'quote',
        help: 'Tweet ID to quote.',
        valueHelp: 'id',
      );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Post a new tweet.';

  @override
  String get invocation => 'x tweet create <text>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <text>');
    }
    final text = args.join(' ');
    final jsonOutput = argResults!['json'] as bool;
    final replyToId = argResults!['reply-to'] as String?;
    final quoteTweetId = argResults!['quote'] as String?;

    final response = await _api.createTweet(
      text,
      replyToId: replyToId,
      quoteTweetId: quoteTweetId,
    );

    if (jsonOutput) {
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(response));
      return 0;
    }

    _printConfirmation(response);
    return 0;
  }

  void _printConfirmation(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      // ignore: avoid_print
      print('Failed to create tweet.');
      return;
    }

    final id = data['id'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    final url = 'https://x.com/i/status/$id';

    final buf = StringBuffer();
    buf.writeln(green('Tweet posted!'));
    buf.writeln();
    buf.writeln(text);
    buf.writeln();
    buf.writeln('ID: $id');
    buf.writeln(cyan(url));

    // ignore: avoid_print
    print(buf.toString().trimRight());
  }
}
