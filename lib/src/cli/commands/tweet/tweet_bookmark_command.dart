import 'package:args/command_runner.dart';

/// Bookmark a tweet.
///
/// ```
/// x tweet bookmark <id>
/// ```
class TweetBookmarkCommand extends Command<int> {
  @override
  String get name => 'bookmark';

  @override
  String get description => 'Bookmark a tweet.';

  @override
  String get invocation => 'x tweet bookmark <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet bookmark');
  }
}
