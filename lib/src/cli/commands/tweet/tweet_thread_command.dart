import 'package:args/command_runner.dart';

/// View a tweet thread (conversation).
///
/// Reconstructs a thread from the conversation_id via search.
/// Note: X API v2 has no dedicated "get thread" endpoint --
/// this uses search within the 7-day recent window.
///
/// ```
/// x tweet thread <id>
/// ```
class TweetThreadCommand extends Command<int> {
  @override
  String get name => 'thread';

  @override
  String get description => 'View a tweet thread (conversation).';

  @override
  String get invocation => 'x tweet thread <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet thread');
  }
}
