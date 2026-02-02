import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

/// Follow a user.
///
/// Accepts a username and resolves it to a user ID before calling the API.
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

    await _api.follow(userId);

    // ignore: avoid_print
    print('Followed @$username');
    return 0;
  }
}
