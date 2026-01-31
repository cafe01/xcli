import 'dart:io';

import 'package:test/test.dart';
import 'package:xcli/src/auth/token.dart';
import 'package:xcli/src/auth/token_store.dart';

void main() {
  late Directory tempDir;
  late TokenStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('xcli_test_');
    store = TokenStore(configDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  OAuthToken makeToken({String accessToken = 'access-123'}) => OAuthToken(
        accessToken: accessToken,
        refreshToken: 'refresh-456',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        username: 'testuser',
        userId: '789',
        scopes: ['tweet.read'],
      );

  group('TokenStore', () {
    test('starts with no accounts', () {
      expect(store.accounts, isEmpty);
      expect(store.activeAccount, isNull);
      expect(store.activeToken, isNull);
    });

    test('saves and retrieves a token', () {
      final token = makeToken();
      store.saveToken('myaccount', token);

      final retrieved = store.getToken('myaccount');
      expect(retrieved, isNotNull);
      expect(retrieved!.accessToken, 'access-123');
      expect(retrieved.refreshToken, 'refresh-456');
    });

    test('sets first saved account as active', () {
      store.saveToken('first', makeToken());
      expect(store.activeAccount, 'first');
    });

    test('setActive=true changes active account', () {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken(accessToken: 'other'));

      expect(store.activeAccount, 'second');
    });

    test('setActive=false preserves existing active', () {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken(), setActive: false);

      expect(store.activeAccount, 'first');
    });

    test('activeToken returns the active account token', () {
      store.saveToken('myaccount', makeToken());
      final token = store.activeToken;

      expect(token, isNotNull);
      expect(token!.accessToken, 'access-123');
    });

    test('lists all accounts', () {
      store.saveToken('alpha', makeToken());
      store.saveToken('beta', makeToken());
      store.saveToken('gamma', makeToken());

      expect(store.accounts, containsAll(['alpha', 'beta', 'gamma']));
      expect(store.accounts.length, 3);
    });

    test('setActiveAccount switches active', () {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken());

      store.setActiveAccount('first');
      expect(store.activeAccount, 'first');
    });

    test('setActiveAccount throws for unknown account', () {
      expect(
        () => store.setActiveAccount('nonexistent'),
        throwsA(isA<StateError>()),
      );
    });

    test('removeToken removes account', () {
      store.saveToken('removeme', makeToken());
      store.removeToken('removeme');

      expect(store.getToken('removeme'), isNull);
      expect(store.accounts, isEmpty);
    });

    test('removeToken switches active when removing active', () {
      store.saveToken('first', makeToken());
      store.saveToken('second', makeToken());
      store.setActiveAccount('first');

      store.removeToken('first');
      expect(store.activeAccount, 'second');
    });

    test('clear removes all data', () {
      store.saveToken('one', makeToken());
      store.saveToken('two', makeToken());
      store.clear();

      expect(store.accounts, isEmpty);
      expect(store.activeAccount, isNull);
    });

    test('persists across store instances', () {
      store.saveToken('persistent', makeToken());

      // Create a new store pointing at the same directory
      final store2 = TokenStore(configDir: tempDir.path);
      final token = store2.getToken('persistent');

      expect(token, isNotNull);
      expect(token!.accessToken, 'access-123');
    });

    test('overwrites existing account token', () {
      store.saveToken('myaccount', makeToken(accessToken: 'old'));
      store.saveToken('myaccount', makeToken(accessToken: 'new'));

      final token = store.getToken('myaccount');
      expect(token!.accessToken, 'new');
    });

    test('configDir returns the configured path', () {
      expect(store.configDir, tempDir.path);
    });
  });
}
