/// Shared output formatting utilities for human-readable CLI output.
///
/// Provides ANSI color helpers, relative time formatting, compact number
/// formatting, and reusable tweet/user formatters used across all commands.
///
/// Color output respects [colorEnabled], which is set by the `--no-color`
/// flag and the `NO_COLOR` environment variable (https://no-color.org).
library;

/// Whether ANSI color output is enabled.
///
/// Defaults to `true`. Set to `false` via the `--no-color` flag or the
/// `NO_COLOR` environment variable.
bool colorEnabled = true;

// ---------------------------------------------------------------------------
// ANSI color helpers
// ---------------------------------------------------------------------------

const _reset = '\x1b[0m';

/// Wrap [s] in ANSI bold. No-op when [colorEnabled] is false.
String bold(String s) => colorEnabled ? '\x1b[1m$s$_reset' : s;

/// Wrap [s] in ANSI dim. No-op when [colorEnabled] is false.
String dim(String s) => colorEnabled ? '\x1b[2m$s$_reset' : s;

/// Wrap [s] in ANSI cyan. No-op when [colorEnabled] is false.
String cyan(String s) => colorEnabled ? '\x1b[36m$s$_reset' : s;

/// Wrap [s] in ANSI green. No-op when [colorEnabled] is false.
String green(String s) => colorEnabled ? '\x1b[32m$s$_reset' : s;

/// Wrap [s] in ANSI yellow. No-op when [colorEnabled] is false.
String yellow(String s) => colorEnabled ? '\x1b[33m$s$_reset' : s;

// ---------------------------------------------------------------------------
// Number formatting
// ---------------------------------------------------------------------------

/// Format a count for compact display.
///
/// - Below 1000: returned as-is (`42`)
/// - 1K -- 999.9K: one decimal when needed (`1.2K`, `10K`)
/// - 1M+: one decimal when needed (`1.5M`, `3M`)
String formatCount(int count) {
  if (count < 1000) return '$count';
  if (count < 1000000) {
    final k = count / 1000;
    final formatted = k.toStringAsFixed(1);
    // 999950+ rounds to 1000.0K -- show as 1M instead.
    if (formatted.startsWith('1000')) return '1M';
    return '${formatted.endsWith('.0') ? '${k.toInt()}' : formatted}K';
  }
  final m = count / 1000000;
  final formatted = m.toStringAsFixed(1);
  return '${formatted.endsWith('.0') ? '${m.toInt()}' : formatted}M';
}

// ---------------------------------------------------------------------------
// Relative time formatting
// ---------------------------------------------------------------------------

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Format an ISO 8601 timestamp as a human-friendly relative time string.
///
/// - Less than 1 minute: `just now`
/// - Less than 60 minutes: `Xm ago`
/// - Less than 24 hours: `Xh ago`
/// - Less than 7 days: `Xd ago`
/// - Same year: `Mon DD` (e.g. `Jan 15`)
/// - Different year: `Mon DD, YYYY` (e.g. `Jan 15, 2025`)
///
/// Pass [now] to override the current time (for deterministic testing).
String formatRelativeTime(String isoTimestamp, {DateTime? now}) {
  final dt = DateTime.parse(isoTimestamp);
  final ref = now ?? DateTime.now();
  final diff = ref.difference(dt);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final month = _months[dt.month - 1];
  if (dt.year == ref.year) return '$month ${dt.day}';
  return '$month ${dt.day}, ${dt.year}';
}

// ---------------------------------------------------------------------------
// Tweet formatting
// ---------------------------------------------------------------------------

/// Resolve an author from the `includes.users` list by matching [authorId].
Map<String, dynamic>? _resolveAuthor(
  String? authorId,
  Map<String, dynamic>? includes,
) {
  if (authorId == null || includes == null) return null;
  final users = includes['users'] as List<dynamic>?;
  if (users == null) return null;
  for (final user in users) {
    final u = user as Map<String, dynamic>;
    if (u['id'] == authorId) return u;
  }
  return null;
}

/// Format a single tweet for human-readable display.
///
/// - [includeMetrics]: show like/retweet/reply counts.
/// - [showId]: prefix the header with `[id]` (useful in list views).
/// - [detail]: add blank lines between sections for a spacious layout.
/// - [includes]: the `includes` object from the API response, used to
///   resolve author usernames.
/// - [now]: override current time for relative timestamps (testing).
String formatTweetLine(
  Map<String, dynamic> tweet, {
  bool includeMetrics = false,
  bool showId = false,
  bool detail = false,
  Map<String, dynamic>? includes,
  DateTime? now,
}) {
  final text = tweet['text'] as String? ?? '';
  final authorId = tweet['author_id'] as String?;
  final createdAt = tweet['created_at'] as String?;
  final metrics = tweet['public_metrics'] as Map<String, dynamic>?;

  final author = _resolveAuthor(authorId, includes);
  final buf = StringBuffer();

  // Optional tweet-ID prefix for list views.
  if (showId) {
    final id = tweet['id'] as String?;
    if (id != null) buf.write(dim('[$id] '));
  }

  // Author header.
  if (author != null) {
    final username = author['username'] as String? ?? 'unknown';
    final name = author['name'] as String? ?? 'Unknown';
    final verified = author['verified'] as bool? ?? false;
    buf.write(bold(cyan('@$username')));
    buf.write(' ($name)');
    if (verified) buf.write(' ${green('\u2713')}');
  } else if (authorId != null) {
    buf.write(dim('@$authorId'));
  } else {
    buf.write(bold(cyan('@unknown')));
    buf.write(' (Unknown)');
  }
  buf.writeln();

  if (detail) buf.writeln(); // blank line before text in detail mode

  // Tweet text.
  buf.writeln(text);

  // Footer: relative timestamp + metrics on one line.
  final footerParts = <String>[];
  if (createdAt != null) {
    footerParts.add(formatRelativeTime(createdAt, now: now));
  }
  if (includeMetrics && metrics != null) {
    final metricParts = <String>[];
    final likes = metrics['like_count'] as int?;
    final retweets = metrics['retweet_count'] as int?;
    final replies = metrics['reply_count'] as int?;
    if (likes != null) metricParts.add('${formatCount(likes)} Likes');
    if (retweets != null) metricParts.add('${formatCount(retweets)} Retweets');
    if (replies != null) metricParts.add('${formatCount(replies)} Replies');
    if (metricParts.isNotEmpty) footerParts.add(metricParts.join('  '));
  }

  if (footerParts.isNotEmpty) {
    if (detail) buf.writeln(); // blank line before footer in detail mode
    buf.writeln(dim(footerParts.join('  ')));
  }

  return buf.toString().trimRight();
}

/// Format a user profile for human-readable display.
///
/// Shows username, display name, verified badge, bio, and follower/following
/// counts with compact number formatting.
String formatUserLine(Map<String, dynamic> userData) {
  final username = userData['username'] as String? ?? 'unknown';
  final name = userData['name'] as String? ?? 'Unknown';
  final bio = userData['description'] as String?;
  final verified = userData['verified'] as bool? ?? false;
  final metrics = userData['public_metrics'] as Map<String, dynamic>?;

  final buf = StringBuffer();

  // Header: @username (Display Name) [verified]
  buf.write(bold(cyan('@$username')));
  buf.write(' ($name)');
  if (verified) buf.write(' ${green('\u2713')}');
  buf.writeln();

  // Bio.
  if (bio != null && bio.isNotEmpty) {
    buf.writeln();
    buf.writeln(bio);
  }

  // Metrics.
  if (metrics != null) {
    buf.writeln();
    final parts = <String>[];
    final followers = metrics['followers_count'] as int?;
    final following = metrics['following_count'] as int?;
    final tweets = metrics['tweet_count'] as int?;
    if (followers != null) parts.add('${formatCount(followers)} Followers');
    if (following != null) parts.add('${formatCount(following)} Following');
    if (tweets != null) parts.add('${formatCount(tweets)} Tweets');
    if (parts.isNotEmpty) buf.writeln(dim(parts.join('  ')));
  }

  return buf.toString().trimRight();
}
