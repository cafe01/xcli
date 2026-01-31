import 'package:args/command_runner.dart';

/// View your home timeline.
///
/// ```
/// x timeline home
/// ```
class TimelineHomeCommand extends Command<int> {
  @override
  String get name => 'home';

  @override
  String get description => 'View your home timeline.';

  @override
  Future<int> run() async {
    throw UnimplementedError('timeline home');
  }
}
