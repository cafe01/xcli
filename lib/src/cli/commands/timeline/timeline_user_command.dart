import 'package:args/command_runner.dart';

/// View a user's timeline.
///
/// ```
/// x timeline user <username>
/// ```
class TimelineUserCommand extends Command<int> {
  @override
  String get name => 'user';

  @override
  String get description => "View a user's timeline.";

  @override
  String get invocation => 'x timeline user <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('timeline user');
  }
}
