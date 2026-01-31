import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../auth/oauth_flow.dart';
import '../../../auth/token_store.dart';

/// Authenticate with X.com via OAuth 2.0 PKCE.
///
/// Resolves client ID from: `--client-id` flag > `X_CLIENT_ID` env var.
/// Opens browser for authorization, then exchanges code for tokens.
///
/// ```
/// x auth login --client-id <id>
/// x auth login                    # uses X_CLIENT_ID env var
/// ```
class AuthLoginCommand extends Command<int> {
  /// Creates the login command.
  AuthLoginCommand({
    required TokenStore tokenStore,
    StringSink? output,
  })  : _tokenStore = tokenStore,
        _output = output ?? stdout {
    argParser
      ..addOption(
        'client-id',
        help: 'X Developer App client ID (or set X_CLIENT_ID env var).',
      )
      ..addOption(
        'port',
        help: 'Localhost port for OAuth callback.',
        defaultsTo: '8914',
      )
      ..addOption(
        'account',
        help: 'Account name for storing credentials.',
        defaultsTo: 'default',
      )
      ..addMultiOption(
        'scopes',
        help: 'OAuth scopes (defaults to all XApi operations).',
      )
      ..addFlag(
        'no-browser',
        negatable: false,
        help: 'Print authorization URL instead of opening browser.',
      );
  }

  final TokenStore _tokenStore;
  final StringSink _output;

  @override
  String get name => 'login';

  @override
  String get description => 'Log in to X.com via browser OAuth flow.';

  @override
  Future<int> run() async {
    final clientId = _resolveClientId();
    if (clientId == null) {
      _output.writeln('Error: No client ID provided.');
      _output.writeln('');
      _output.writeln('Set client ID via:');
      _output.writeln('  x auth login --client-id <YOUR_CLIENT_ID>');
      _output.writeln('  export X_CLIENT_ID=<YOUR_CLIENT_ID>');
      _output.writeln('');
      _output.writeln('Get a client ID at: https://developer.x.com/en/portal');
      return 1;
    }

    final port = int.parse(argResults!['port'] as String);
    final accountName = argResults!['account'] as String;
    final noBrowser = argResults!['no-browser'] as bool;
    final scopeArgs = argResults!['scopes'] as List<String>;
    final scopes = scopeArgs.isNotEmpty ? scopeArgs : null;

    final flow = OAuthFlow(clientId: clientId, redirectPort: port);
    final auth = flow.buildAuthorizationUrl(scopes: scopes);

    _output.writeln('Logging in to X.com...');
    _output.writeln('');

    if (noBrowser) {
      _output.writeln('Open this URL in your browser:');
      _output.writeln(auth.url);
    } else {
      _output.writeln('Opening browser for authorization...');
      final opened = await OAuthFlow.openBrowser(auth.url);
      if (!opened) {
        _output.writeln('Could not open browser. Open this URL manually:');
        _output.writeln(auth.url);
      }
    }

    _output.writeln('');
    _output.writeln('Waiting for authorization (port $port)...');

    try {
      final code = await flow.waitForCallback(expectedState: auth.state);
      _output.writeln('Authorization received. Exchanging code for tokens...');

      final token = await flow.exchangeCode(
        code: code,
        codeVerifier: auth.codeVerifier,
      );

      _tokenStore.saveToken(accountName, token);
      _output.writeln('');
      _output.writeln('Logged in as account "$accountName".');
      _output.writeln(
        'Token expires: ${token.expiresAt.toLocal()}',
      );
      _output.writeln(
        'Scopes: ${token.scopes.join(", ")}',
      );
      return 0;
    } on OAuthException catch (e) {
      _output.writeln('');
      _output.writeln('Login failed: ${e.message}');
      return 1;
    }
  }

  String? _resolveClientId() {
    // 1. Command-line flag
    final fromFlag = argResults?['client-id'] as String?;
    if (fromFlag != null && fromFlag.isNotEmpty) return fromFlag;

    // 2. Environment variable
    final fromEnv = Platform.environment['X_CLIENT_ID'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    return null;
  }
}
