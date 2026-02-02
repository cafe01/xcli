import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

/// Unfollow a user.
///
/// Accepts a username and resolves it to a user ID before calling the API.
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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <username>');
    }
    final username = args.first;

    // Resolve username to user ID.
    final userResponse = await _api.getUser(username);
    final userData = userResponse['data'] as Map<String, dynamic>;
    final userId = userData['id'] as String;

    await _api.unfollow(userId);

    // ignore: avoid_print
    print('Unfollowed @$username');
    return 0;
  }
}
