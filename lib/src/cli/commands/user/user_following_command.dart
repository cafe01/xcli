import 'package:args/command_runner.dart';

/// List users a user is following.
///
/// ```
/// x user following <username>
/// ```
class UserFollowingCommand extends Command<int> {
  @override
  String get name => 'following';

  @override
  String get description => 'List who a user follows.';

  @override
  String get invocation => 'x user following <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user following');
  }
}
