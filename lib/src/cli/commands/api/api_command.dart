import 'package:args/command_runner.dart';

/// Raw X API v2 escape hatch.
///
/// Make arbitrary API requests, similar to `gh api`.
///
/// ```
/// x api <endpoint> [-X method] [-f key=val] [--paginate] [--jq expr]
/// ```
class ApiCommand extends Command<int> {
  ApiCommand() {
    argParser
      ..addOption(
        'method',
        abbr: 'X',
        defaultsTo: 'GET',
        help: 'HTTP method (GET, POST, PUT, DELETE).',
      )
      ..addMultiOption(
        'field',
        abbr: 'f',
        help: 'Add a key=value pair to the request body.',
      )
      ..addFlag(
        'paginate',
        negatable: false,
        help: 'Automatically paginate through all results.',
      )
      ..addOption(
        'jq',
        help: 'JQ expression to filter the response.',
      );
  }

  @override
  String get name => 'api';

  @override
  String get description => 'Make raw X API v2 requests.';

  @override
  String get invocation => 'x api <endpoint>';

  @override
  Future<int> run() async {
    throw UnimplementedError('api');
  }
}
