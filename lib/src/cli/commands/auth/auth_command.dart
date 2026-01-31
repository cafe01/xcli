import 'package:args/command_runner.dart';

import '../../../auth/token_store.dart';
import 'auth_login_command.dart';
import 'auth_logout_command.dart';
import 'auth_status_command.dart';
import 'auth_switch_command.dart';

/// Parent command for authentication.
///
/// ```
/// x auth login|logout|status|switch
/// ```
class AuthCommand extends Command<int> {
  /// Creates the auth command group.
  ///
  /// [tokenStore] defaults to standard `~/.config/xcli` location.
  /// [output] defaults to stdout (injectable for testing).
  AuthCommand({TokenStore? tokenStore, StringSink? output}) {
    final store = tokenStore ?? TokenStore();
    addSubcommand(AuthLoginCommand(tokenStore: store, output: output));
    addSubcommand(AuthLogoutCommand(tokenStore: store, output: output));
    addSubcommand(AuthStatusCommand(tokenStore: store, output: output));
    addSubcommand(AuthSwitchCommand(tokenStore: store, output: output));
  }

  @override
  String get name => 'auth';

  @override
  String get description => 'Authenticate with X.com (OAuth 2.0 PKCE).';
}
