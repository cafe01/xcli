import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.bookmarkTweet(id);

    // ignore: avoid_print
    print('Bookmarked tweet $id');
    return 0;
  }
}
