import 'package:args/command_runner.dart';

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
  AuthCommand() {
    addSubcommand(AuthLoginCommand());
    addSubcommand(AuthLogoutCommand());
    addSubcommand(AuthStatusCommand());
    addSubcommand(AuthSwitchCommand());
  }

  @override
  String get name => 'auth';

  @override
  String get description => 'Authenticate with X.com (OAuth 2.0 PKCE).';
}
