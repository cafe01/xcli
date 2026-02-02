import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.unlikeTweet(id);

    // ignore: avoid_print
    print('Unliked tweet $id');
    return 0;
  }
}
