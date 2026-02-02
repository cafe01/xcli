import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.likeTweet(id);

    // ignore: avoid_print
    print('Liked tweet $id');
    return 0;
  }
}
