import 'package:args/command_runner.dart';

/// Search users by username.
///
/// Note: X API v2 only supports exact username lookup, not fuzzy search.
///
/// ```
/// x search users <query>
/// ```
class SearchUsersCommand extends Command<int> {
  @override
  String get name => 'users';

  @override
  String get description => 'Look up users by username.';

  @override
  String get invocation => 'x search users <query>';

  @override
  Future<int> run() async {
    throw UnimplementedError('search users');
  }
}
