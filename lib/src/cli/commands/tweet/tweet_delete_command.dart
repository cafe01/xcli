import 'package:args/command_runner.dart';

import '../../../api/x_api.dart';
import '../../x_runner.dart';

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

  XApi get _api => (runner! as XCommandRunner).api;

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing required argument: <id>');
    }
    final id = args.first;

    await _api.deleteTweet(id);

    // ignore: avoid_print
    print('Deleted tweet $id');
    return 0;
  }
}
