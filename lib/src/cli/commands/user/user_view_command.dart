import 'package:args/command_runner.dart';

/// View a user profile by username.
///
/// ```
/// x user view <username>
/// ```
class UserViewCommand extends Command<int> {
  @override
  String get name => 'view';

  @override
  String get description => 'View a user profile.';

  @override
  String get invocation => 'x user view <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user view');
  }
}
