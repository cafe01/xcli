import 'package:args/command_runner.dart';

/// Get a configuration value.
///
/// ```
/// x config get <key>
/// ```
class ConfigGetCommand extends Command<int> {
  @override
  String get name => 'get';

  @override
  String get description => 'Get a configuration value.';

  @override
  String get invocation => 'x config get <key>';

  @override
  Future<int> run() async {
    throw UnimplementedError('config get');
  }
}
