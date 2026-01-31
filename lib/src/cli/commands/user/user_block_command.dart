import 'package:args/command_runner.dart';

/// Block a user.
///
/// ```
/// x user block <username>
/// ```
class UserBlockCommand extends Command<int> {
  @override
  String get name => 'block';

  @override
  String get description => 'Block a user.';

  @override
  String get invocation => 'x user block <username>';

  @override
  Future<int> run() async {
    throw UnimplementedError('user block');
  }
}
