import 'package:args/command_runner.dart';

/// Follow a user.
///
/// ```
/// x user follow <username>
/// ```
class UserFollowCommand extends Command<int> {
  @override
  String get name => 'follow';

  @override
  String get description => 'Follow a user.';

  @override
  String get invocation => 'x user follow <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user follow');
  }
}
