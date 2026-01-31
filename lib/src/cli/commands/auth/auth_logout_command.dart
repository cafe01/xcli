import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../auth/token_store.dart';

/// Log out of X.com (clear stored credentials).
///
/// Removes tokens for the specified account, or the active account
/// if none specified.
///
/// ```
/// x auth logout           # logout active account
/// x auth logout mybot     # logout specific account
/// x auth logout --all     # logout all accounts
/// ```
class AuthLogoutCommand extends Command<int> {
  /// Creates the logout command.
  AuthLogoutCommand({
    required TokenStore tokenStore,
    StringSink? output,
  })  : _tokenStore = tokenStore,
        _output = output ?? stdout {
    argParser.addFlag(
      'all',
      negatable: false,
      help: 'Log out of all accounts.',
    );
  }

  final TokenStore _tokenStore;
  final StringSink _output;

  @override
  String get name => 'logout';

  @override
  String get description => 'Log out and revoke stored credentials.';

  @override
  String get invocation => 'x auth logout [account]';

  @override
  Future<int> run() async {
    final logoutAll = argResults!['all'] as bool;

    if (logoutAll) {
      final accounts = _tokenStore.accounts;
      if (accounts.isEmpty) {
        _output.writeln('No accounts to log out.');
        return 0;
      }
      _tokenStore.clear();
      _output.writeln(
        'Logged out of ${accounts.length} account(s): '
        '${accounts.join(", ")}',
      );
      return 0;
    }

    // Specific account from positional arg, or active account
    final rest = argResults!.rest;
    final account = rest.isNotEmpty ? rest.first : _tokenStore.activeAccount;

    if (account == null) {
      _output.writeln('No active account. Nothing to log out.');
      return 0;
    }

    final token = _tokenStore.getToken(account);
    if (token == null) {
      _output.writeln('Account "$account" not found.');
      return 1;
    }

    _tokenStore.removeToken(account);
    _output.writeln('Logged out of account "$account".');
    return 0;
  }
}
