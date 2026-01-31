import 'package:args/command_runner.dart';

/// Authenticate with X.com via OAuth 2.0 PKCE.
///
/// ```
/// x auth login
/// ```
class AuthLoginCommand extends Command<int> {
  @override
  String get name => 'login';

  @override
  String get description => 'Log in to X.com via browser OAuth flow.';

  @override
  Future<int> run() async {
    throw UnimplementedError('auth login');
  }
}
