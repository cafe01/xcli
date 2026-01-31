import 'package:args/command_runner.dart';

/// Undo a retweet.
///
/// ```
/// x tweet unretweet <id>
/// ```
class TweetUnretweetCommand extends Command<int> {
  @override
  String get name => 'unretweet';

  @override
  String get description => 'Undo a retweet.';

  @override
  String get invocation => 'x tweet unretweet <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet unretweet');
  }
}
