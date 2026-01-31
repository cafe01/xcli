import 'package:args/command_runner.dart';

/// Delete a tweet by ID.
///
/// ```
/// x tweet delete <id>
/// ```
class TweetDeleteCommand extends Command<int> {
  @override
  String get name => 'delete';

  @override
  String get description => 'Delete a tweet by ID.';

  @override
  String get invocation => 'x tweet delete <id>';

  @override
  Future<int> run() async {
    throw UnimplementedError('tweet delete');
  }
}
