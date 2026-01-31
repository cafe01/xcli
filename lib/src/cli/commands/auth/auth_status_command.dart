import 'package:args/command_runner.dart';

/// Show authentication status.
///
/// ```
/// x auth status
/// ```
class AuthStatusCommand extends Command<int> {
  @override
  String get name => 'status';

  @override
  String get description => 'Show current authentication status.';

  @override
  Future<int> run() async {
    throw UnimplementedError('auth status');
  }
}
