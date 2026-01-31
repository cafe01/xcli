import 'package:args/command_runner.dart';

/// Quote-tweet another tweet.
///
/// ```
/// x tweet quote <id> <text>
/// ```
class TweetQuoteCommand extends Command<int> {
  @override
  String get name => 'quote';

  @override
  String get description => 'Quote-tweet another tweet.';

  @override
  String get invocation => 'x tweet quote <id> <text>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet quote');
  }
}
