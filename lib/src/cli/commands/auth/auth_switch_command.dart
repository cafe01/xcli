import 'dart:io';

import 'package:args/command_runner.dart';

import '../../../auth/token_store.dart';

/// Switch active account.
///
/// ```
/// x auth switch mybot
/// ```
class AuthSwitchCommand extends Command<int> {
  /// Creates the switch command.
  AuthSwitchCommand({
    required TokenStore tokenStore,
    StringSink? output,
  })  : _tokenStore = tokenStore,
        _output = output ?? stdout;

  final TokenStore _tokenStore;
  final StringSink _output;

  @override
  String get name => 'switch';

  @override
  String get description => 'Switch to a different authenticated account.';

  @override
  String get invocation => 'x auth switch <account>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      final accounts = _tokenStore.accounts;
      if (accounts.isEmpty) {
        _output.writeln('No accounts available. Run "x auth login" first.');
        return 1;
      }
      final active = _tokenStore.activeAccount;
      _output.writeln('Available accounts:');
      for (final account in accounts) {
        final marker = account == active ? '* ' : '  ';
        _output.writeln('$marker$account');
      }
      _output.writeln('');
      _output.writeln('Usage: x auth switch <account>');
      return 1;
    }

    final account = rest.first;

    try {
      _tokenStore.setActiveAccount(account);
      _output.writeln('Switched to account "$account".');
      return 0;
    } on StateError catch (e) {
      _output.writeln('Error: ${e.message}');
      return 1;
    }
  }
}
