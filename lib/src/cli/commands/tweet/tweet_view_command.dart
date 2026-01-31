import 'package:args/command_runner.dart';

/// View a tweet by ID.
///
/// ```
/// x tweet view <id>
/// ```
class TweetViewCommand extends Command<int> {
  @override
  String get name => 'view';

  @override
  String get description => 'View a tweet by ID.';

  @override
  String get invocation => 'x tweet view <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet view');
  }
}
