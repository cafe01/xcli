import 'package:args/command_runner.dart';

import 'timeline_home_command.dart';
import 'timeline_mentions_command.dart';
import 'timeline_user_command.dart';

/// Parent command for timeline operations.
///
/// ```
/// x timeline [home|mentions|user <username>]
/// ```
class TimelineCommand extends Command<int> {
  TimelineCommand() {
    addSubcommand(TimelineHomeCommand());
    addSubcommand(TimelineMentionsCommand());
    addSubcommand(TimelineUserCommand());
  }

  @override
  String get name => 'timeline';

  @override
  String get description => 'View home feed, mentions, and user timelines.';
}
