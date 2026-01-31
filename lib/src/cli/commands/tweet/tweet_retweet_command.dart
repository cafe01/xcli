import 'package:args/command_runner.dart';

/// Retweet a tweet.
///
/// ```
/// x tweet retweet <id>
/// ```
class TweetRetweetCommand extends Command<int> {
  @override
  String get name => 'retweet';

  @override
  String get description => 'Retweet a tweet.';

  @override
  String get invocation => 'x tweet retweet <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet retweet');
  }
}
