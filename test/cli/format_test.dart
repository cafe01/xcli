import 'package:test/test.dart';
import 'package:xcli/src/cli/format.dart';

void main() {
  // Disable color for deterministic assertions unless explicitly testing color.
  setUp(() {
    colorEnabled = false;
  });

  // ---------------------------------------------------------------
  // formatRelativeTime
  // ---------------------------------------------------------------
  group('formatRelativeTime', () {
    final now = DateTime.utc(2026, 2, 2, 12, 0, 0);

    test('returns "just now" for less than 1 minute ago', () {
      expect(
        formatRelativeTime('2026-02-02T11:59:30.000Z', now: now),
        'just now',
      );
    });

    test('returns "just now" at 0 seconds', () {
      expect(
        formatRelativeTime('2026-02-02T12:00:00.000Z', now: now),
        'just now',
      );
    });

    test('returns "1m ago" at exactly 1 minute', () {
      expect(
        formatRelativeTime('2026-02-02T11:59:00.000Z', now: now),
        '1m ago',
      );
    });

    test('returns "Xm ago" for less than 60 minutes', () {
      expect(
        formatRelativeTime('2026-02-02T11:45:00.000Z', now: now),
        '15m ago',
      );
    });

    test('returns "59m ago" just under 1 hour', () {
      expect(
        formatRelativeTime('2026-02-02T11:01:00.000Z', now: now),
        '59m ago',
      );
    });

    test('returns "1h ago" at exactly 1 hour', () {
      expect(
        formatRelativeTime('2026-02-02T11:00:00.000Z', now: now),
        '1h ago',
      );
    });

    test('returns "Xh ago" for less than 24 hours', () {
      expect(
        formatRelativeTime('2026-02-02T09:00:00.000Z', now: now),
        '3h ago',
      );
    });

    test('returns "23h ago" just under 1 day', () {
      expect(
        formatRelativeTime('2026-02-01T13:00:00.000Z', now: now),
        '23h ago',
      );
    });

    test('returns "1d ago" at exactly 1 day', () {
      expect(
        formatRelativeTime('2026-02-01T12:00:00.000Z', now: now),
        '1d ago',
      );
    });

    test('returns "Xd ago" for less than 7 days', () {
      expect(
        formatRelativeTime('2026-01-31T12:00:00.000Z', now: now),
        '2d ago',
      );
    });

    test('returns "6d ago" at 6 days', () {
      expect(
        formatRelativeTime('2026-01-27T12:00:00.000Z', now: now),
        '6d ago',
      );
    });

    test('returns "Mon DD" for same year beyond 7 days', () {
      expect(
        formatRelativeTime('2026-01-15T12:00:00.000Z', now: now),
        'Jan 15',
      );
    });

    test('returns "Mon DD, YYYY" for different year', () {
      expect(
        formatRelativeTime('2025-06-15T12:00:00.000Z', now: now),
        'Jun 15, 2025',
      );
    });

    test('returns "Mon DD, YYYY" for far past dates', () {
      expect(
        formatRelativeTime('2020-12-25T00:00:00.000Z', now: now),
        'Dec 25, 2020',
      );
    });

    test('uses DateTime.now() when now is not provided', () {
      // A timestamp from 2020 should always be a date, never "Xm ago".
      final result = formatRelativeTime('2020-01-01T00:00:00.000Z');
      expect(result, 'Jan 1, 2020');
    });
  });

  // ---------------------------------------------------------------
  // formatCount
  // ---------------------------------------------------------------
  group('formatCount', () {
    test('returns small numbers unchanged', () {
      expect(formatCount(0), '0');
      expect(formatCount(1), '1');
      expect(formatCount(42), '42');
      expect(formatCount(999), '999');
    });

    test('formats exact thousands without decimal', () {
      expect(formatCount(1000), '1K');
      expect(formatCount(5000), '5K');
      expect(formatCount(10000), '10K');
      expect(formatCount(100000), '100K');
    });

    test('formats thousands with one decimal', () {
      expect(formatCount(1200), '1.2K');
      expect(formatCount(1500), '1.5K');
      expect(formatCount(10500), '10.5K');
      expect(formatCount(999900), '999.9K');
    });

    test('formats exact millions without decimal', () {
      expect(formatCount(1000000), '1M');
      expect(formatCount(5000000), '5M');
    });

    test('formats millions with one decimal', () {
      expect(formatCount(1500000), '1.5M');
      expect(formatCount(3400000), '3.4M');
    });
  });

  // ---------------------------------------------------------------
  // ANSI color helpers
  // ---------------------------------------------------------------
  group('color helpers', () {
    test('return plain text when colorEnabled is false', () {
      colorEnabled = false;
      expect(bold('hello'), 'hello');
      expect(dim('hello'), 'hello');
      expect(cyan('hello'), 'hello');
      expect(green('hello'), 'hello');
      expect(yellow('hello'), 'hello');
    });

    test('wrap text with ANSI codes when colorEnabled is true', () {
      colorEnabled = true;
      expect(bold('hello'), '\x1b[1mhello\x1b[0m');
      expect(dim('hello'), '\x1b[2mhello\x1b[0m');
      expect(cyan('hello'), '\x1b[36mhello\x1b[0m');
      expect(green('hello'), '\x1b[32mhello\x1b[0m');
      expect(yellow('hello'), '\x1b[33mhello\x1b[0m');
    });

    test('handle empty strings', () {
      colorEnabled = true;
      expect(bold(''), '\x1b[1m\x1b[0m');
      colorEnabled = false;
      expect(bold(''), '');
    });
  });

  // ---------------------------------------------------------------
  // formatTweetLine
  // ---------------------------------------------------------------
  group('formatTweetLine', () {
    test('formats tweet with resolved author from includes', () {
      final tweet = <String, dynamic>{
        'id': '123',
        'text': 'Hello world',
        'author_id': '999',
        'created_at': '2026-02-02T11:00:00.000Z',
        'public_metrics': <String, dynamic>{
          'like_count': 42,
          'retweet_count': 7,
          'reply_count': 3,
        },
      };
      final includes = <String, dynamic>{
        'users': <dynamic>[
          <String, dynamic>{
            'id': '999',
            'username': 'testuser',
            'name': 'Test User',
          },
        ],
      };
      final now = DateTime.utc(2026, 2, 2, 12, 0, 0);

      final result = formatTweetLine(
        tweet,
        includeMetrics: true,
        includes: includes,
        now: now,
      );

      expect(result, contains('@testuser'));
      expect(result, contains('Test User'));
      expect(result, contains('Hello world'));
      expect(result, contains('1h ago'));
      expect(result, contains('42 Likes'));
      expect(result, contains('7 Retweets'));
      expect(result, contains('3 Replies'));
    });

    test('falls back to @authorId when no includes', () {
      final tweet = <String, dynamic>{
        'id': '100',
        'text': 'First tweet',
        'author_id': '10',
      };

      final result = formatTweetLine(tweet);

      expect(result, contains('@10'));
      expect(result, contains('First tweet'));
    });

    test('falls back to @unknown when no author info at all', () {
      final tweet = <String, dynamic>{
        'id': '100',
        'text': 'Orphan tweet',
      };

      final result = formatTweetLine(tweet);

      expect(result, contains('@unknown'));
      expect(result, contains('Orphan tweet'));
    });

    test('shows tweet ID when showId is true', () {
      final tweet = <String, dynamic>{
        'id': '100',
        'text': 'Test',
        'author_id': '10',
      };

      final result = formatTweetLine(tweet, showId: true);

      expect(result, contains('[100]'));
    });

    test('hides tweet ID when showId is false', () {
      final tweet = <String, dynamic>{
        'id': '100',
        'text': 'Test',
        'author_id': '10',
      };

      final result = formatTweetLine(tweet, showId: false);

      expect(result, isNot(contains('[100]')));
    });

    test('adds blank lines in detail mode', () {
      final tweet = <String, dynamic>{
        'id': '123',
        'text': 'Hello',
        'author_id': '999',
        'created_at': '2026-02-02T11:00:00.000Z',
        'public_metrics': <String, dynamic>{'like_count': 1},
      };
      final includes = <String, dynamic>{
        'users': <dynamic>[
          <String, dynamic>{
            'id': '999',
            'username': 'u',
            'name': 'U',
          },
        ],
      };
      final now = DateTime.utc(2026, 2, 2, 12, 0, 0);

      final compact = formatTweetLine(
        tweet,
        includeMetrics: true,
        includes: includes,
        now: now,
      );
      final detailed = formatTweetLine(
        tweet,
        includeMetrics: true,
        detail: true,
        includes: includes,
        now: now,
      );

      // Detail mode should have more lines (blank lines inserted).
      final compactLines = compact.split('\n').length;
      final detailLines = detailed.split('\n').length;
      expect(detailLines, greaterThan(compactLines));
    });

    test('omits metrics when includeMetrics is false', () {
      final tweet = <String, dynamic>{
        'id': '123',
        'text': 'Hello',
        'public_metrics': <String, dynamic>{'like_count': 42},
      };

      final result = formatTweetLine(tweet);

      expect(result, isNot(contains('Likes')));
    });

    test('shows verified badge for verified author', () {
      final tweet = <String, dynamic>{
        'id': '123',
        'text': 'Hello',
        'author_id': '999',
      };
      final includes = <String, dynamic>{
        'users': <dynamic>[
          <String, dynamic>{
            'id': '999',
            'username': 'v',
            'name': 'V',
            'verified': true,
          },
        ],
      };

      final result = formatTweetLine(tweet, includes: includes);

      expect(result, contains('\u2713'));
    });

    test('omits verified badge for non-verified author', () {
      final tweet = <String, dynamic>{
        'id': '123',
        'text': 'Hello',
        'author_id': '999',
      };
      final includes = <String, dynamic>{
        'users': <dynamic>[
          <String, dynamic>{
            'id': '999',
            'username': 'v',
            'name': 'V',
            'verified': false,
          },
        ],
      };

      final result = formatTweetLine(tweet, includes: includes);

      expect(result, isNot(contains('\u2713')));
    });

    test('handles missing text gracefully', () {
      final tweet = <String, dynamic>{'id': '1'};

      final result = formatTweetLine(tweet);

      // Should not throw, returns something with @unknown.
      expect(result, contains('@unknown'));
    });

    test('uses compact count formatting in metrics', () {
      final tweet = <String, dynamic>{
        'id': '1',
        'text': 'Big numbers',
        'public_metrics': <String, dynamic>{
          'like_count': 12500,
          'retweet_count': 3400000,
          'reply_count': 99,
        },
      };

      final result = formatTweetLine(tweet, includeMetrics: true);

      expect(result, contains('12.5K Likes'));
      expect(result, contains('3.4M Retweets'));
      expect(result, contains('99 Replies'));
    });
  });

  // ---------------------------------------------------------------
  // formatUserLine
  // ---------------------------------------------------------------
  group('formatUserLine', () {
    test('formats full user profile', () {
      final user = <String, dynamic>{
        'username': 'testuser',
        'name': 'Test User',
        'description': 'A bio.',
        'verified': true,
        'public_metrics': <String, dynamic>{
          'followers_count': 1200,
          'following_count': 300,
          'tweet_count': 5000,
        },
      };

      final result = formatUserLine(user);

      expect(result, contains('@testuser'));
      expect(result, contains('Test User'));
      expect(result, contains('\u2713'));
      expect(result, contains('A bio.'));
      expect(result, contains('1.2K Followers'));
      expect(result, contains('300 Following'));
      expect(result, contains('5K Tweets'));
    });

    test('omits bio when not present', () {
      final user = <String, dynamic>{
        'username': 'nobi',
        'name': 'No Bio',
      };

      final result = formatUserLine(user);

      expect(result, contains('@nobi'));
      expect(result, contains('No Bio'));
    });

    test('omits bio when empty string', () {
      final user = <String, dynamic>{
        'username': 'empty',
        'name': 'Empty',
        'description': '',
      };

      final result = formatUserLine(user);

      // Should not have a blank section for empty bio.
      expect(result, contains('@empty'));
    });

    test('omits verified badge when not verified', () {
      final user = <String, dynamic>{
        'username': 'test',
        'name': 'Test',
        'verified': false,
      };

      final result = formatUserLine(user);

      expect(result, isNot(contains('\u2713')));
    });

    test('omits metrics when not present', () {
      final user = <String, dynamic>{
        'username': 'test',
        'name': 'Test',
      };

      final result = formatUserLine(user);

      expect(result, isNot(contains('Followers')));
      expect(result, isNot(contains('Following')));
      expect(result, isNot(contains('Tweets')));
    });

    test('uses compact count formatting for large numbers', () {
      final user = <String, dynamic>{
        'username': 'big',
        'name': 'Big Account',
        'public_metrics': <String, dynamic>{
          'followers_count': 1500000,
          'following_count': 200,
          'tweet_count': 45000,
        },
      };

      final result = formatUserLine(user);

      expect(result, contains('1.5M Followers'));
      expect(result, contains('200 Following'));
      expect(result, contains('45K Tweets'));
    });

    test('defaults to @unknown when username is missing', () {
      final user = <String, dynamic>{'name': 'No Username'};

      final result = formatUserLine(user);

      expect(result, contains('@unknown'));
    });
  });

  // ---------------------------------------------------------------
  // --no-color integration
  // ---------------------------------------------------------------
  group('colorEnabled integration', () {
    test('formatTweetLine output is plain text with no color', () {
      colorEnabled = false;
      final tweet = <String, dynamic>{
        'id': '1',
        'text': 'Plain',
        'author_id': '10',
      };

      final result = formatTweetLine(tweet, showId: true);

      // No ANSI escape codes should be present.
      expect(result, isNot(contains('\x1b[')));
      expect(result, contains('[1]'));
      expect(result, contains('@10'));
      expect(result, contains('Plain'));
    });

    test('formatTweetLine output has ANSI codes with color enabled', () {
      colorEnabled = true;
      final tweet = <String, dynamic>{
        'id': '1',
        'text': 'Colored',
        'author_id': '10',
      };

      final result = formatTweetLine(tweet, showId: true);

      expect(result, contains('\x1b['));
    });

    test('formatUserLine output is plain text with no color', () {
      colorEnabled = false;
      final user = <String, dynamic>{
        'username': 'plain',
        'name': 'Plain',
        'verified': true,
        'public_metrics': <String, dynamic>{
          'followers_count': 100,
        },
      };

      final result = formatUserLine(user);

      expect(result, isNot(contains('\x1b[')));
      expect(result, contains('@plain'));
      expect(result, contains('\u2713'));
    });

    test('formatUserLine output has ANSI codes with color enabled', () {
      colorEnabled = true;
      final user = <String, dynamic>{
        'username': 'color',
        'name': 'Color',
      };

      final result = formatUserLine(user);

      expect(result, contains('\x1b['));
    });
  });
}
