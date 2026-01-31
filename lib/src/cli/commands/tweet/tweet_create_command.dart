import 'package:args/command_runner.dart';

/// Create a new tweet.
///
/// ```
/// x tweet create <text>
/// ```
class TweetCreateCommand extends Command<int> {
  @override
  String get name => 'create';

  @override
  String get description => 'Post a new tweet.';

  @override
  String get invocation => 'x tweet create <text>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet create');
  }
}
