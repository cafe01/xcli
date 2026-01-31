import 'package:args/command_runner.dart';

/// Parent command for list operations (stub group).
///
/// ```
/// x list view|create|edit|delete|tweets|members|add-member|remove-member
/// ```
class ListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description => 'Create and manage curated lists. (stub)';

  @override
  Future<int> run() async {
    throw UnimplementedError('list (stub group -- subcommands pending)');
  }
}
