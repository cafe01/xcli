import 'package:args/command_runner.dart';

/// Unfollow a user.
///
/// ```
/// x user unfollow <username>
/// ```
class UserUnfollowCommand extends Command<int> {
  @override
  String get name => 'unfollow';

  @override
  String get description => 'Unfollow a user.';

  @override
  String get invocation => 'x user unfollow <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user unfollow');
  }
}
