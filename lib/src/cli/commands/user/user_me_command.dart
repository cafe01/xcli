import 'package:args/command_runner.dart';

/// View the authenticated user's profile.
///
/// ```
/// x user me
/// ```
class UserMeCommand extends Command<int> {
  @override
  String get name => 'me';

  @override
  String get description => 'View your own profile.';

  @override
  Future<int> run() async {
    throw UnimplementedError('user me');
  }
}
