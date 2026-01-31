import 'package:args/command_runner.dart';

import 'config_get_command.dart';
import 'config_list_command.dart';
import 'config_set_command.dart';

/// Parent command for configuration.
///
/// ```
/// x config get|set|list
/// ```
class ConfigCommand extends Command<int> {
  ConfigCommand() {
    addSubcommand(ConfigGetCommand());
    addSubcommand(ConfigSetCommand());
    addSubcommand(ConfigListCommand());
  }

  @override
  String get name => 'config';

  @override
  String get description => 'Manage CLI configuration.';
}
