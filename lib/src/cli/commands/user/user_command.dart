import 'package:args/command_runner.dart';

import 'user_block_command.dart';
import 'user_follow_command.dart';
import 'user_followers_command.dart';
import 'user_following_command.dart';
import 'user_me_command.dart';
import 'user_mute_command.dart';
import 'user_unfollow_command.dart';
import 'user_view_command.dart';

/// Parent command for user operations.
///
/// ```
/// x user view|me|follow|unfollow|followers|following|block|mute
/// ```
class UserCommand extends Command<int> {
  UserCommand() {
    addSubcommand(UserViewCommand());
    addSubcommand(UserMeCommand());
    addSubcommand(UserFollowCommand());
    addSubcommand(UserUnfollowCommand());
    addSubcommand(UserFollowersCommand());
    addSubcommand(UserFollowingCommand());
    addSubcommand(UserBlockCommand());
    addSubcommand(UserMuteCommand());
  }

  @override
  String get name => 'user';

  @override
  String get description => 'View profiles and manage relationships.';
}
