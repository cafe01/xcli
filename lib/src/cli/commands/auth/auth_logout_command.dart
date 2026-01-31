import 'package:args/command_runner.dart';

/// Log out of X.com (revoke credentials).
///
/// ```
/// x auth logout
/// ```
class AuthLogoutCommand extends Command<int> {
  @override
  String get name => 'logout';

  @override
  String get description => 'Log out and revoke stored credentials.';

  @override
  Future<int> run() async {
    throw UnimplementedError('auth logout');
  }
}
