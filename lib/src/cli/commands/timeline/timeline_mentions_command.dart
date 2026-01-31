import 'package:args/command_runner.dart';

/// View your mentions.
///
/// ```
/// x timeline mentions
/// ```
class TimelineMentionsCommand extends Command<int> {
  @override
  String get name => 'mentions';

  @override
  String get description => 'View tweets mentioning you.';

  @override
  Future<int> run() async {
    throw UnimplementedError('timeline mentions');
  }
}
