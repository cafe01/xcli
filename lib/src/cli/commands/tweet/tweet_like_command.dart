import 'package:args/command_runner.dart';

/// Like a tweet.
///
/// ```
/// x tweet like <id>
/// ```
class TweetLikeCommand extends Command<int> {
  @override
  String get name => 'like';

  @override
  String get description => 'Like a tweet.';

  @override
  String get invocation => 'x tweet like <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet like');
  }
}
