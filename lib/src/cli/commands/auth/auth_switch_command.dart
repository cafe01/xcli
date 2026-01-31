import 'package:args/command_runner.dart';

/// Switch active account.
///
/// ```
/// x auth switch <account>
/// ```
class AuthSwitchCommand extends Command<int> {
  @override
  String get name => 'switch';

  @override
  String get description => 'Switch to a different authenticated account.';

  @override
  String get invocation => 'x auth switch <account>';

  @override
  Future<int> run() async {
    throw UnimplementedError('auth switch');
  }
}
