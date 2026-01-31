import 'package:args/command_runner.dart';

/// Unlike a tweet.
///
/// ```
/// x tweet unlike <id>
/// ```
class TweetUnlikeCommand extends Command<int> {
  @override
  String get name => 'unlike';

  @override
  String get description => 'Unlike a tweet.';

  @override
  String get invocation => 'x tweet unlike <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet unlike');
  }
}
