import 'package:args/command_runner.dart';

/// List bookmarked tweets.
///
/// ```
/// x tweet bookmarks
/// ```
class TweetBookmarksCommand extends Command<int> {
  @override
  String get name => 'bookmarks';

  @override
  String get description => 'List your bookmarked tweets.';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet bookmarks');
  }
}
