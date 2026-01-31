import 'package:args/command_runner.dart';

/// List all configuration values.
///
/// ```
/// x config list
/// ```
class ConfigListCommand extends Command<int> {
  @override
  String get name => 'list';

  @override
  String get description => 'List all configuration values.';

  @override
  Future<int> run() async {
    throw UnimplementedError('config list');
  }
}
