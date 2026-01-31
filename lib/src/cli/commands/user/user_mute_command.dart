import 'package:args/command_runner.dart';

/// Mute a user.
///
/// ```
/// x user mute <username>
/// ```
class UserMuteCommand extends Command<int> {
  @override
  String get name => 'mute';

  @override
  String get description => 'Mute a user.';

  @override
  String get invocation => 'x user mute <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user mute');
  }
}
