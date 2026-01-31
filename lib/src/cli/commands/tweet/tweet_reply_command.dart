import 'package:args/command_runner.dart';

/// Reply to a tweet.
///
/// ```
/// x tweet reply <id> <text>
/// ```
class TweetReplyCommand extends Command<int> {
  @override
  String get name => 'reply';

  @override
  String get description => 'Reply to a tweet.';

  @override
  String get invocation => 'x tweet reply <id> <text>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet reply');
  }
}
