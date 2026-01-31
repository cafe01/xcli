import 'package:args/command_runner.dart';

/// Parent command for direct message operations (stub group).
///
/// Note: DM endpoints require Pro tier ($5K/mo) on X API v2.
///
/// ```
/// x dm send|list|view|delete
/// ```
class DmCommand extends Command<int> {
  @override
  String get name => 'dm';

  @override
  String get description => 'Send and view direct messages. (stub)';

  @override
  Future<int> run() async {
    throw UnimplementedError('dm (stub group -- subcommands pending)');
  }
}
