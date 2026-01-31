import 'dart:convert';

import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

/// View a tweet by ID.
///
/// ```
/// x tweet view <id> [--json] [--fields <fields>]
/// ```
///
/// Default output is human-readable. Use `--json` for raw API response.
class TweetViewCommand extends Command<int> {
  TweetViewCommand() {
    argParser
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output raw JSON response.',
      )
      ..addMultiOption(
        'fields',
        help: 'Additional tweet fields to request.',
        valueHelp: 'field1,field2',
      );
  }

  @override
  String get name => 'view';

  @override
  String get description => 'View a tweet by ID.';

  @override
  String get invocation => 'x tweet view <id>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;
    final jsonOutput = argResults!['json'] as bool;

    // Request expansions for human-readable output (author info + metrics).
    final response = await _api.getTweet(
      id,
      expansions: ['author_id'],
      tweetFields: [
        'created_at',
        'public_metrics',
        'text',
        'conversation_id',
      ],
      userFields: ['name', 'username', 'verified'],
    );

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
      print('Tweet not found.');
      return;
    }

    // Resolve author from includes.
    final includes = response['includes'] as Map<String, dynamic>?;
    final users = includes?['users'] as List<dynamic>?;
    Map<String, dynamic>? author;
    if (users != null && users.isNotEmpty) {
      author = users.first as Map<String, dynamic>;
    }

    final text = data['text'] as String? ?? '';
    final authorName = author?['name'] as String? ?? 'Unknown';
    final authorUsername = author?['username'] as String? ?? 'unknown';
    final createdAt = data['created_at'] as String?;
    final metrics = data['public_metrics'] as Map<String, dynamic>?;

    final buf = StringBuffer();

    // Header: @username (Display Name)
    buf.writeln('@$authorUsername ($authorName)');
    buf.writeln();

    // Tweet text
    buf.writeln(text);
    buf.writeln();

    // Timestamp
    if (createdAt != null) {
      buf.writeln(createdAt);
    }

    // Metrics
    if (metrics != null) {
      final parts = <String>[];
      final likes = metrics['like_count'];
      final retweets = metrics['retweet_count'];
      final replies = metrics['reply_count'];
      if (likes != null) parts.add('$likes Likes');
      if (retweets != null) parts.add('$retweets Retweets');
      if (replies != null) parts.add('$replies Replies');
      if (parts.isNotEmpty) buf.writeln(parts.join('  '));
    }

    // ignore: avoid_print
    print(buf.toString().trimRight());
  }
}
