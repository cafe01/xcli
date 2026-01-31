import 'package:args/command_runner.dart';

/// Set a configuration value.
///
/// ```
/// x config set <key> <value>
/// ```
class ConfigSetCommand extends Command<int> {
  @override
  String get name => 'set';

  @override
  String get description => 'Set a configuration value.';

  @override
  String get invocation => 'x config set <key> <value>';

  @override
  Future<int> run() async {
    throw UnimplementedError('config set');
  }
}
