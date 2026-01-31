import 'package:args/command_runner.dart';

/// List a user's followers.
///
/// ```
/// x user followers <username>
/// ```
class UserFollowersCommand extends Command<int> {
  @override
  String get name => 'followers';

  @override
  String get description => "List a user's followers.";

  @override
  String get invocation => 'x user followers <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user followers');
  }
}
