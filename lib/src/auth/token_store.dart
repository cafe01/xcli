import 'dart:convert';
import 'dart:io';

import 'token.dart';

/// Persistent storage for OAuth tokens, supporting multiple accounts.
///
/// Stores tokens as JSON at `~/.config/xcli/accounts.json`:
/// ```json
/// {
///   "active": "account-name",
///   "accounts": {
///     "account-name": { ...token fields... }
///   }
/// }
/// ```
class TokenStore {
  /// Creates a token store at the given [configDir].
  ///
  /// Defaults to `~/.config/xcli` if not specified.
  TokenStore({String? configDir})
      : _configDir = configDir ?? defaultConfigDir();

  final String _configDir;

  /// Default config directory: `~/.config/xcli`.
  static String defaultConfigDir() {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return '$home/.config/xcli';
  }

  String get _accountsFile => '$_configDir/accounts.json';

  /// Load all stored data from disk.
  Map<String, dynamic> _readStore() {
    final file = File(_accountsFile);
    if (!file.existsSync()) return <String, dynamic>{};
    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Persist data to disk.
  void _writeStore(Map<String, dynamic> store) {
    final dir = Directory(_configDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File(_accountsFile);
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(store));
  }

  /// Get the active account name.
  String? get activeAccount {
    final store = _readStore();
    return store['active'] as String?;
  }

  /// Set the active account.
  ///
  /// Throws [StateError] if the account does not exist.
  void setActiveAccount(String account) {
    final store = _readStore();
    final accounts =
        store['accounts'] as Map<String, dynamic>? ?? <String, dynamic>{};
    if (!accounts.containsKey(account)) {
      throw StateError('Account "$account" not found.');
    }
    store['active'] = account;
    _writeStore(store);
  }

  /// Save a token for an account.
  ///
  /// Sets the account as active if [setActive] is true (default)
  /// or if no active account is set.
  void saveToken(String account, OAuthToken token, {bool setActive = true}) {
    final store = _readStore();
    final accounts =
        store['accounts'] as Map<String, dynamic>? ?? <String, dynamic>{};
    accounts[account] = token.toJson();
    store['accounts'] = accounts;
    if (setActive || store['active'] == null) {
      store['active'] = account;
    }
    _writeStore(store);
  }

  /// Get the token for a specific account.
  OAuthToken? getToken(String account) {
    final store = _readStore();
    final accounts =
        store['accounts'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data = accounts[account] as Map<String, dynamic>?;
    if (data == null) return null;
    return OAuthToken.fromJson(data);
  }

  /// Get the active account's token.
  OAuthToken? get activeToken {
    final account = activeAccount;
    if (account == null) return null;
    return getToken(account);
  }

  /// List all stored account names.
  List<String> get accounts {
    final store = _readStore();
    final accts =
        store['accounts'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return accts.keys.toList();
  }

  /// Remove a specific account's token.
  void removeToken(String account) {
    final store = _readStore();
    final accounts =
        store['accounts'] as Map<String, dynamic>? ?? <String, dynamic>{};
    accounts.remove(account);
    store['accounts'] = accounts;
    if (store['active'] == account) {
      store['active'] =
          accounts.keys.isEmpty ? null : accounts.keys.first;
    }
    _writeStore(store);
  }

  /// Remove all stored tokens and the accounts file.
  void clear() {
    final file = File(_accountsFile);
    if (file.existsSync()) file.deleteSync();
  }

  /// The config directory path.
  String get configDir => _configDir;
}
