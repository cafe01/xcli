import 'package:args/command_runner.dart';

/// Search recent tweets.
///
/// ```
/// x search tweets <query>
/// ```
class SearchTweetsCommand extends Command<int> {
  @override
  String get name => 'tweets';

  @override
  String get description => 'Search recent tweets.';

  @override
  String get invocation => 'x search tweets <query>';

  @override
  Future<int> run() async {
    throw UnimplementedError('search tweets');
  }
}
