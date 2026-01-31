import 'package:args/command_runner.dart';

import 'tweet_bookmark_command.dart';
import 'tweet_bookmarks_command.dart';
import 'tweet_create_command.dart';
import 'tweet_delete_command.dart';
import 'tweet_like_command.dart';
import 'tweet_quote_command.dart';
import 'tweet_reply_command.dart';
import 'tweet_retweet_command.dart';
import 'tweet_thread_command.dart';
import 'tweet_unlike_command.dart';
import 'tweet_unretweet_command.dart';
import 'tweet_view_command.dart';

/// Parent command for tweet operations.
///
/// ```
/// x tweet view|create|delete|reply|quote|thread|like|unlike|
///        retweet|unretweet|bookmark|bookmarks
/// ```
class TweetCommand extends Command<int> {
  TweetCommand() {
    addSubcommand(TweetViewCommand());
    addSubcommand(TweetCreateCommand());
    addSubcommand(TweetDeleteCommand());
    addSubcommand(TweetReplyCommand());
    addSubcommand(TweetQuoteCommand());
    addSubcommand(TweetThreadCommand());
    addSubcommand(TweetLikeCommand());
    addSubcommand(TweetUnlikeCommand());
    addSubcommand(TweetRetweetCommand());
    addSubcommand(TweetUnretweetCommand());
    addSubcommand(TweetBookmarkCommand());
    addSubcommand(TweetBookmarksCommand());
  }

  @override
  String get name => 'tweet';

  @override
  String get description => 'Read, create, and manage tweets.';
}
