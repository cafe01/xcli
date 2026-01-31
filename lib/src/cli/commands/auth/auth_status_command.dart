import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../auth/token_store.dart';

/// Show authentication status.
///
/// Displays active account, token expiry, and granted scopes.
///
/// ```
/// x auth status
/// ```
class AuthStatusCommand extends Command<int> {
  /// Creates the status command.
  AuthStatusCommand({
    required TokenStore tokenStore,
    StringSink? output,
  })  : _tokenStore = tokenStore,
        _output = output ?? stdout;

  final TokenStore _tokenStore;
  final StringSink _output;

  @override
  String get name => 'status';

  @override
  String get description => 'Show current authentication status.';

  @override
  Future<int> run() async {
    final accounts = _tokenStore.accounts;

    if (accounts.isEmpty) {
      _output.writeln('Not logged in.');
      _output.writeln('Run "x auth login" to authenticate.');
      return 0;
    }

    final active = _tokenStore.activeAccount;

    for (final account in accounts) {
      final token = _tokenStore.getToken(account);
      if (token == null) continue;

      final isActive = account == active;
      final marker = isActive ? '* ' : '  ';
      final status = token.isExpired ? 'EXPIRED' : 'active';
      final expiry = token.expiresAt.toLocal();

      _output.writeln('$marker$account ($status)');
      _output.writeln('    Token expires: $expiry');
      if (token.scopes.isNotEmpty) {
        _output.writeln('    Scopes: ${token.scopes.join(", ")}');
      }
    }

    _output.writeln('');
    _output.writeln('Config: ${_tokenStore.configDir}');
    return 0;
  }
}
