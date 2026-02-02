import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.retweet(id);

    // ignore: avoid_print
    print('Retweeted tweet $id');
    return 0;
  }
}
