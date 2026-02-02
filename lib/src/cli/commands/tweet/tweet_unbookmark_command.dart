import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

/// Remove a bookmark from a tweet.
///
/// ```
/// x tweet unbookmark <id>
/// ```
class TweetUnbookmarkCommand extends Command<int> {
  @override
  String get name => 'unbookmark';

  @override
  String get description => 'Remove a bookmark from a tweet.';

  @override
  String get invocation => 'x tweet unbookmark <id>';

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.unbookmarkTweet(id);

    // ignore: avoid_print
    print('Unbookmarked tweet $id');
    return 0;
  }
}
