# xcli User's Manual

Complete reference for the `x` command-line tool for X.com (formerly Twitter).

Version 0.1.0 | Dart 3.8+

---

## Table of contents

1. [Installation](#installation)
2. [Getting started](#getting-started)
3. [Core concepts](#core-concepts)
4. [Command reference](#command-reference)
   - [Tweet commands](#tweet-commands)
   - [User commands](#user-commands)
   - [Timeline commands](#timeline-commands)
   - [Search commands](#search-commands)
   - [Auth commands](#auth-commands)
   - [Plumbing commands](#plumbing-commands)
5. [Multi-account management](#multi-account-management)
6. [For agents](#for-agents)
7. [Troubleshooting](#troubleshooting)
8. [API coverage](#api-coverage)

---

## Installation

### Building from source

xcli requires Dart SDK 3.8 or later.

```bash
# Clone the repository
git clone https://github.com/cafe01/xcli.git
cd xcli

# Compile to native executable
dart compile exe packages/xcli/bin/x.dart -o x

# Verify the build
./x --version
# x version 0.1.0
```

### Adding to PATH

```bash
# Option 1: Copy to a directory already in PATH
sudo cp x /usr/local/bin/x

# Option 2: Add the build directory to PATH
export PATH="$PATH:$(pwd)"

# Verify
x --version
```

### Running without compiling

You can also run directly with `dart run`:

```bash
cd packages/xcli
dart run bin/x.dart --version
```

---

## Getting started

### Prerequisites

1. A X.com account
2. A developer app at [developer.x.com](https://developer.x.com/en/portal)
3. The app's Client ID (PKCE flow does not require a client secret)
4. Callback URL set to `http://localhost:8914/callback` in your app settings

### First-time authentication

```bash
# Set your client ID
export X_CLIENT_ID="your-client-id"

# Start the login flow
x auth login
```

This will:
1. Open your browser to the X.com authorization page
2. Start a local HTTP server on port 8914 to receive the callback
3. Exchange the authorization code for access and refresh tokens
4. Store the tokens at `~/.config/xcli/accounts.json`

If the browser cannot be opened automatically, use `--no-browser`:

```bash
x auth login --no-browser
# Prints the authorization URL to copy into your browser
```

### Verifying authentication

```bash
# Check auth status
x auth status
```

```
* default (active)
    Token expires: 2026-02-01 14:30:00.000
    Scopes: tweet.read, tweet.write, users.read, follows.read, follows.write, like.read, like.write, bookmark.read, bookmark.write, block.read, block.write, mute.read, mute.write, list.read, list.write, offline.access

Config: /Users/you/.config/xcli
```

```bash
# Verify API access works
x user me
```

```
@yourname (Your Display Name)

Your bio text here

1.2K Followers  300 Following  5K Tweets
```

---

## Core concepts

### Human-readable vs JSON output

Most read commands support two output modes:

**Human-readable** (default): Formatted text with ANSI colors, relative timestamps ("2h ago", "3d ago"), and compact number formatting ("1.2K", "3M").

**JSON** (`--json` flag): The raw X API v2 response, pretty-printed with 2-space indentation. Ideal for piping to `jq`, scripting, or agent consumption.

```bash
# Human-readable
x user view torvalds

# JSON
x user view torvalds --json
```

### Global flags

These flags apply to all commands:

| Flag | Short | Description |
|------|-------|-------------|
| `--version` | | Print `x version 0.1.0` and exit |
| `--account <name>` | `-a` | Use a specific authenticated account for this command |
| `--verbose` | | Enable verbose output |
| `--no-color` | | Disable ANSI color codes in output |

The `NO_COLOR` environment variable is also respected (see [no-color.org](https://no-color.org)):

```bash
NO_COLOR=1 x timeline home
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Application error (auth failure, API error) |
| 64 | Usage error (missing argument, invalid flag) |

### Account selection

Commands use the active account by default. Override with `-a`:

```bash
x -a mybot timeline mentions
```

---

## Command reference

### Tweet commands

Parent command: `x tweet <subcommand>`

#### x tweet view

View a tweet by ID.

**Syntax:**
```
x tweet view <id> [--json] [--fields <fields>]
```

**Arguments:**
- `<id>` (required): The tweet ID

**Flags:**
- `--json`: Output raw JSON response
- `--fields <fields>`: Additional tweet fields to request (multi-option)

**Human-readable output:**
```bash
x tweet view 1893482057301849
```

```
@openai (OpenAI)

We're releasing a new model today. It's our most capable yet.

3h ago  12.5K Likes  2.1K Retweets  890 Replies
```

**JSON output:**
```bash
x tweet view 1893482057301849 --json
```

```json
{
  "data": {
    "id": "1893482057301849",
    "text": "We're releasing a new model today. It's our most capable yet.",
    "author_id": "11348282",
    "created_at": "2026-01-31T18:00:00.000Z",
    "conversation_id": "1893482057301849",
    "public_metrics": {
      "like_count": 12500,
      "retweet_count": 2100,
      "reply_count": 890
    }
  },
  "includes": {
    "users": [
      {
        "id": "11348282",
        "name": "OpenAI",
        "username": "openai",
        "verified": true
      }
    ]
  }
}
```

**Error cases:**
- Missing ID argument: exits 64 with usage message
- Tweet not found: prints "Tweet not found."
- 401 Unauthorized: throws `AuthException`

---

#### x tweet create

Post a new tweet.

**Syntax:**
```
x tweet create <text> [--reply-to <id>] [--quote <id>] [--json]
```

**Arguments:**
- `<text>` (required): The tweet text. Multiple words are joined with spaces.

**Flags:**
- `--reply-to <id>`: Tweet ID to reply to
- `--quote <id>`: Tweet ID to quote
- `--json`: Output raw JSON response

**Examples:**

```bash
# Simple tweet
x tweet create "Hello from the command line"
```

```
Tweet posted!

Hello from the command line

ID: 1893500000000001
https://x.com/i/status/1893500000000001
```

```bash
# Reply to a tweet
x tweet create "Great point!" --reply-to 1893482057301849
```

```bash
# Quote tweet
x tweet create "This is worth reading" --quote 1893482057301849
```

```bash
# JSON output
x tweet create "Testing" --json
```

```json
{
  "data": {
    "id": "1893500000000001",
    "text": "Testing"
  }
}
```

**Note:** The `--reply-to` and `--quote` flags on `create` are the implemented way to reply and quote. The standalone `x tweet reply` and `x tweet quote` commands are stubs.

---

#### x tweet delete

Delete a tweet by ID.

**Syntax:**
```
x tweet delete <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to delete

**Example:**
```bash
x tweet delete 1893500000000001
```

```
Deleted tweet 1893500000000001
```

---

#### x tweet like

Like a tweet.

**Syntax:**
```
x tweet like <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to like

**Example:**
```bash
x tweet like 1893482057301849
```

```
Liked tweet 1893482057301849
```

---

#### x tweet unlike

Unlike a tweet.

**Syntax:**
```
x tweet unlike <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to unlike

**Example:**
```bash
x tweet unlike 1893482057301849
```

```
Unliked tweet 1893482057301849
```

---

#### x tweet retweet

Retweet a tweet.

**Syntax:**
```
x tweet retweet <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to retweet

**Example:**
```bash
x tweet retweet 1893482057301849
```

```
Retweeted tweet 1893482057301849
```

---

#### x tweet unretweet

Undo a retweet.

**Syntax:**
```
x tweet unretweet <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to unretweet

**Example:**
```bash
x tweet unretweet 1893482057301849
```

```
Unretweeted tweet 1893482057301849
```

---

#### x tweet bookmark

Bookmark a tweet.

**Syntax:**
```
x tweet bookmark <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to bookmark

**Example:**
```bash
x tweet bookmark 1893482057301849
```

```
Bookmarked tweet 1893482057301849
```

---

#### x tweet unbookmark

Remove a bookmark from a tweet.

**Syntax:**
```
x tweet unbookmark <id>
```

**Arguments:**
- `<id>` (required): The tweet ID to unbookmark

**Example:**
```bash
x tweet unbookmark 1893482057301849
```

```
Unbookmarked tweet 1893482057301849
```

---

#### x tweet bookmarks

List your bookmarked tweets.

**Syntax:**
```
x tweet bookmarks [--json]
```

**Flags:**
- `--json`: Output raw JSON response

**Human-readable output:**
```bash
x tweet bookmarks
```

```
[1893482057301849] @openai (OpenAI)
We're releasing a new model today.

---

[1893400000000001] @torvalds (Linus Torvalds)
Another day, another kernel release.
```

**Empty state:**
```
No bookmarks found.
```

---

#### x tweet reply (coming soon)

Reply to a tweet. Currently a stub that throws `UnimplementedError`.

**Note:** You can reply now using `x tweet create <text> --reply-to <id>`.

---

#### x tweet quote (coming soon)

Quote-tweet another tweet. Currently a stub.

**Note:** You can quote now using `x tweet create <text> --quote <id>`.

---

#### x tweet thread (coming soon)

View a tweet thread (conversation). Will reconstruct threads using conversation_id via search within the 7-day recent window.

---

### User commands

Parent command: `x user <subcommand>`

#### x user view

View a user profile by username.

**Syntax:**
```
x user view <username> [--json]
```

**Arguments:**
- `<username>` (required): The X.com username (without @)

**Flags:**
- `--json`: Output raw JSON response

**Human-readable output:**
```bash
x user view torvalds
```

```
@torvalds (Linus Torvalds) [checkmark]

Linux and git.

593.2K Followers  1 Following  581 Tweets
```

The checkmark appears for verified accounts. Metrics use compact formatting: "1.2K", "3M".

**JSON output:**
```bash
x user view torvalds --json
```

```json
{
  "data": {
    "id": "218aborttorva",
    "username": "torvalds",
    "name": "Linus Torvalds",
    "description": "Linux and git.",
    "verified": true,
    "public_metrics": {
      "followers_count": 593200,
      "following_count": 1,
      "tweet_count": 581
    }
  }
}
```

**Error cases:**
- Missing username: exits 64 with usage message
- User not found: prints "User not found."

---

#### x user me

View the authenticated user's own profile.

**Syntax:**
```
x user me [--json]
```

**Flags:**
- `--json`: Output raw JSON response

**Example:**
```bash
x user me
```

```
@yourname (Your Display Name)

Building tools for the open web.

1.2K Followers  300 Following  5K Tweets
```

**Error case:**
- Not authenticated: prints "Could not retrieve profile."

---

#### x user follow

Follow a user by username. Internally resolves the username to a user ID before calling the follow API.

**Syntax:**
```
x user follow <username>
```

**Arguments:**
- `<username>` (required): The username to follow

**Example:**
```bash
x user follow torvalds
```

```
Followed @torvalds
```

---

#### x user unfollow

Unfollow a user by username. Internally resolves the username to a user ID.

**Syntax:**
```
x user unfollow <username>
```

**Arguments:**
- `<username>` (required): The username to unfollow

**Example:**
```bash
x user unfollow torvalds
```

```
Unfollowed @torvalds
```

---

#### x user followers (coming soon)

List a user's followers. Currently a stub.

---

#### x user following (coming soon)

List who a user follows. Currently a stub.

---

#### x user block (coming soon)

Block a user. Currently a stub.

---

#### x user mute (coming soon)

Mute a user. Currently a stub.

---

### Timeline commands

Parent command: `x timeline <subcommand>`

All timeline commands display tweets in a list format with `---` separators between entries. Each tweet shows `[id]`, author, text, and metadata.

#### x timeline home

View your home timeline (reverse chronological).

**Syntax:**
```
x timeline home [--json]
```

**Flags:**
- `--json`: Output raw JSON response

**Human-readable output:**
```bash
x timeline home
```

```
[1893500000000010] @openai (OpenAI)
We're releasing a new model today.

---

[1893500000000009] @github (GitHub)
Copilot just got an upgrade.

---

[1893500000000008] @dart_lang (Dart)
Dart 3.8 is now available.
```

**Empty state:**
```
No tweets found.
```

---

#### x timeline mentions

View tweets mentioning you.

**Syntax:**
```
x timeline mentions [--json]
```

**Flags:**
- `--json`: Output raw JSON response

**Example:**
```bash
x timeline mentions
```

```
[1893500000000015] @friend (A Friend)
@yourname check this out!

---

[1893500000000012] @colleague (Work Colleague)
@yourname great work on the release
```

**Empty state:**
```
No mentions found.
```

---

#### x timeline user

View a user's timeline. Accepts a username and resolves it to a user ID internally.

**Syntax:**
```
x timeline user <username> [--json]
```

**Arguments:**
- `<username>` (required): The username whose timeline to view

**Flags:**
- `--json`: Output raw JSON response

**Example:**
```bash
x timeline user torvalds
```

```
[1893500000000020] @torvalds (Linus Torvalds)
Another day, another kernel release.

---

[1893500000000018] @torvalds (Linus Torvalds)
I really do not like unnecessary complexity.
```

**Empty state:**
```
No tweets found.
```

---

### Search commands

Parent command: `x search <subcommand>`

#### x search tweets

Search recent tweets matching a query. Uses the X API v2 recent search endpoint (7-day window).

**Syntax:**
```
x search tweets <query> [--json]
```

**Arguments:**
- `<query>` (required): Search query string. Multiple words are joined with spaces. Supports X API v2 search operators.

**Flags:**
- `--json`: Output raw JSON response

**Human-readable output:**
```bash
x search tweets "dart programming"
```

```
3 results

[1893500000000030] @dart_lang (Dart)
Dart 3.8 brings exciting new features for CLI developers.

---

[1893500000000025] @developer (Jane Dev)
Just shipped my first Dart CLI tool. The args package is great.

---

[1893500000000020] @coder (Code Smith)
Dart programming tip: use sealed classes for exhaustive pattern matching.
```

**Empty state:**
```
No tweets found.
```

---

#### x search users (coming soon)

Look up users by username. Currently a stub. Note: X API v2 only supports exact username lookup, not fuzzy search.

---

### Auth commands

Parent command: `x auth <subcommand>`

#### x auth login

Authenticate with X.com via OAuth 2.0 PKCE browser flow.

**Syntax:**
```
x auth login [--client-id <id>] [--port <port>] [--account <name>] [--scopes <scopes>] [--no-browser]
```

**Flags:**
- `--client-id <id>`: X Developer App client ID. If not provided, reads from `X_CLIENT_ID` environment variable.
- `--port <port>`: Localhost port for OAuth callback (default: `8914`)
- `--account <name>`: Account name for storing credentials (default: `default`)
- `--scopes <scopes>`: OAuth scopes (default: all XApi operations + offline.access)
- `--no-browser`: Print authorization URL instead of opening browser

**Default scopes requested:**
`tweet.read`, `tweet.write`, `users.read`, `follows.read`, `follows.write`, `like.read`, `like.write`, `bookmark.read`, `bookmark.write`, `block.read`, `block.write`, `mute.read`, `mute.write`, `list.read`, `list.write`, `offline.access`

**Example:**
```bash
export X_CLIENT_ID="abc123"
x auth login --account personal
```

```
Logging in to X.com...

Opening browser for authorization...

Waiting for authorization (port 8914)...
Authorization received. Exchanging code for tokens...

Logged in as account "personal".
Token expires: 2026-02-01 14:30:00.000
Scopes: tweet.read, tweet.write, users.read, ...
```

**Error: no client ID:**
```
Error: No client ID provided.

Set client ID via:
  x auth login --client-id <YOUR_CLIENT_ID>
  export X_CLIENT_ID=<YOUR_CLIENT_ID>

Get a client ID at: https://developer.x.com/en/portal
```

**Headless / SSH usage:**
```bash
x auth login --no-browser
# Copy the printed URL to a browser on another machine
```

---

#### x auth logout

Log out and remove stored credentials.

**Syntax:**
```
x auth logout [account] [--all]
```

**Arguments:**
- `[account]` (optional): Account name to log out. Defaults to the active account.

**Flags:**
- `--all`: Log out of all accounts

**Examples:**
```bash
# Logout active account
x auth logout
```

```
Logged out of account "default".
```

```bash
# Logout specific account
x auth logout mybot
```

```
Logged out of account "mybot".
```

```bash
# Logout all accounts
x auth logout --all
```

```
Logged out of 2 account(s): default, mybot
```

---

#### x auth status

Show current authentication status for all stored accounts.

**Syntax:**
```
x auth status
```

**Example (authenticated):**
```bash
x auth status
```

```
* personal (active)
    Token expires: 2026-02-01 14:30:00.000
    Scopes: tweet.read, tweet.write, users.read, follows.read, follows.write, like.read, like.write, bookmark.read, bookmark.write, offline.access
  bot (active)
    Token expires: 2026-02-02 10:00:00.000
    Scopes: tweet.read, tweet.write, users.read

Config: /Users/you/.config/xcli
```

The `*` prefix marks the currently active account. Token status shows "active" or "EXPIRED".

**Example (not authenticated):**
```
Not logged in.
Run "x auth login" to authenticate.
```

---

#### x auth switch

Switch the active account.

**Syntax:**
```
x auth switch <account>
```

**Arguments:**
- `<account>` (required): The account name to switch to

**Example:**
```bash
x auth switch bot
```

```
Switched to account "bot".
```

**When called without argument, lists available accounts:**
```bash
x auth switch
```

```
Available accounts:
* personal
  bot

Usage: x auth switch <account>
```

---

### Plumbing commands

These commands are registered but not yet implemented. They throw `UnimplementedError` when invoked.

#### x api (coming soon)

Raw X API v2 escape hatch, similar to `gh api`. Planned flags:

```
x api <endpoint> [-X method] [-f key=val] [--paginate] [--jq expr]
```

- `-X, --method <method>`: HTTP method (GET, POST, PUT, DELETE). Default: GET.
- `-f, --field <key=value>`: Add key-value pairs to the request body.
- `--paginate`: Automatically page through all results.
- `--jq <expr>`: JQ expression to filter the response.

#### x config (coming soon)

CLI configuration management.

```
x config get <key>
x config set <key> <value>
x config list
```

#### x dm (coming soon)

Direct message operations. Note: DM endpoints require the Pro tier ($5K/month) on X API v2.

#### x list (coming soon)

Curated list management (create, edit, delete, view members, add/remove members).

---

## Multi-account management

xcli supports multiple authenticated accounts stored in `~/.config/xcli/accounts.json`.

### Setting up multiple accounts

```bash
# Login with named accounts
export X_CLIENT_ID="your-client-id"
x auth login --account personal
x auth login --account work-bot

# Check what's stored
x auth status
```

### Switching accounts

```bash
# Permanently switch the active account
x auth switch work-bot

# Use a different account for a single command
x -a personal tweet create "Personal tweet"
x -a work-bot timeline home
```

### Token file format

The file at `~/.config/xcli/accounts.json` has this structure:

```json
{
  "active": "personal",
  "accounts": {
    "personal": {
      "access_token": "...",
      "refresh_token": "...",
      "expires_at": "2026-02-01T14:30:00.000Z",
      "scopes": ["tweet.read", "tweet.write", "..."]
    },
    "work-bot": {
      "access_token": "...",
      "refresh_token": "...",
      "expires_at": "2026-02-02T10:00:00.000Z",
      "scopes": ["tweet.read", "tweet.write", "..."]
    }
  }
}
```

### Removing accounts

```bash
# Remove one account
x auth logout work-bot

# Remove all accounts
x auth logout --all
```

When the active account is removed, the first remaining account becomes active.

---

## For agents

xcli is designed to work well as a tool for AI agents and automation scripts. This section covers recommended patterns.

### Always use JSON mode

Agents should always pass `--json` to get structured, parseable output. Human-readable output includes ANSI escape codes and relative timestamps that are harder to process reliably.

```bash
# Get a tweet as structured data
x tweet view 1234567890 --json

# Get your user ID
x user me --json
```

### Disable color output

To avoid ANSI escape codes in output:

```bash
export NO_COLOR=1
# Or: x --no-color <command>
```

### Error handling

xcli uses typed exceptions that produce specific exit codes:

| Exit code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Parse stdout |
| 1 | API/auth error | Check stderr for message |
| 64 | Usage error (bad args) | Fix the command syntax |

HTTP-level errors from the X API:
- **401 Unauthorized**: Token expired or revoked. Re-run `x auth login`.
- **404 Not Found**: Tweet deleted or user does not exist.
- **429 Too Many Requests**: Rate limit exceeded. Back off and retry.

### Typical agent workflows

**Monitor mentions and respond:**
```bash
# 1. Check mentions
mentions=$(x timeline mentions --json)

# 2. Extract tweet IDs that need a response
# (use jq or your language's JSON parser)

# 3. Reply to each
x tweet create "Thanks for the mention!" --reply-to "$tweet_id"
```

**Post a thread using reply chaining:**
```bash
# Post first tweet
result=$(x tweet create "Thread (1/3): First point" --json)
id1=$(echo "$result" | jq -r '.data.id')

# Chain replies
result=$(x tweet create "Thread (2/3): Second point" --reply-to "$id1" --json)
id2=$(echo "$result" | jq -r '.data.id')

x tweet create "Thread (3/3): Conclusion" --reply-to "$id2"
```

**Gather user information:**
```bash
# Get a user profile
x user view elonmusk --json | jq '{
  username: .data.username,
  followers: .data.public_metrics.followers_count,
  tweets: .data.public_metrics.tweet_count
}'
```

**Search and engage:**
```bash
# Search for relevant tweets
x search tweets "your-keyword" --json | jq '.data[].id' | while read id; do
  x tweet like "$id"
done
```

### Account selection for multi-agent setups

If running multiple agents with different X.com accounts:

```bash
x -a bot-alpha tweet create "From bot alpha"
x -a bot-beta timeline mentions --json
```

---

## Troubleshooting

### 401 Unauthorized

**Symptoms:** `AuthException: Unauthorized` or commands failing silently.

**Causes:**
- Token has expired and automatic refresh failed
- Token was revoked on x.com
- Client ID mismatch between login and runtime

**Solutions:**
```bash
# Check token status
x auth status

# Re-authenticate
x auth login
```

Tokens are automatically refreshed 5 minutes before expiry. If the refresh token itself is invalid (e.g., app permissions changed on X.com), you must re-authenticate.

### 429 Too Many Requests

**Symptoms:** `RateLimitException` after many rapid API calls.

**Causes:** X API v2 rate limits vary by endpoint and access tier.

**Solutions:**
- Wait 15 minutes (most rate limits reset in 15-minute windows)
- Reduce request frequency
- Check your app's rate limit tier at [developer.x.com](https://developer.x.com)

### Token expired

**Symptoms:** `x auth status` shows "EXPIRED" next to an account.

**Solutions:**
- xcli automatically refreshes tokens on use (5-minute buffer)
- If auto-refresh fails, re-authenticate: `x auth login --account <name>`

### "Error: No client ID provided"

**Symptoms:** Running `x auth login` without setting a client ID.

**Solutions:**
```bash
# Set via environment variable
export X_CLIENT_ID="your-client-id"

# Or pass directly
x auth login --client-id "your-client-id"
```

### "Could not start callback server on port 8914"

**Symptoms:** Port 8914 is already in use by another process.

**Solutions:**
```bash
# Use a different port
x auth login --port 9000
```

Remember to update your app's callback URL to match: `http://localhost:9000/callback`.

### "OAuth state mismatch"

**Symptoms:** CSRF protection triggered during login.

**Causes:** The state parameter in the callback does not match the one generated during authorization. This can happen if you have multiple login attempts in progress.

**Solutions:** Close all browser tabs with X.com authorization pages and try again.

### Command throws "UnimplementedError"

**Symptoms:** Running a command that prints `UnimplementedError: <command name>`.

**Cause:** The command is registered but not yet implemented (stub).

**Solution:** Check the [command reference](#command-reference) for which commands are implemented vs coming soon.

---

## API coverage

### Implemented endpoints

| CLI Command | X API v2 Endpoint | Method |
|-------------|-------------------|--------|
| `x tweet view <id>` | `/2/tweets/:id` | GET |
| `x tweet create <text>` | `/2/tweets` | POST |
| `x tweet delete <id>` | `/2/tweets/:id` | DELETE |
| `x tweet like <id>` | `/2/users/:id/likes` | POST |
| `x tweet unlike <id>` | `/2/users/:id/likes/:tweet_id` | DELETE |
| `x tweet retweet <id>` | `/2/users/:id/retweets` | POST |
| `x tweet unretweet <id>` | `/2/users/:id/retweets/:tweet_id` | DELETE |
| `x tweet bookmark <id>` | `/2/users/:id/bookmarks` | POST |
| `x tweet unbookmark <id>` | `/2/users/:id/bookmarks/:tweet_id` | DELETE |
| `x tweet bookmarks` | `/2/users/:id/bookmarks` | GET |
| `x user view <username>` | `/2/users/by/username/:username` | GET |
| `x user me` | `/2/users/me` | GET |
| `x user follow <username>` | `/2/users/:id/following` | POST |
| `x user unfollow <username>` | `/2/users/:id/following/:target_id` | DELETE |
| `x timeline home` | `/2/users/:id/timelines/reverse_chronological` | GET |
| `x timeline mentions` | `/2/users/:id/mentions` | GET |
| `x timeline user <username>` | `/2/users/:id/tweets` | GET |
| `x search tweets <query>` | `/2/tweets/search/recent` | GET |

### Stubbed endpoints (planned)

| CLI Command | X API v2 Endpoint | Method |
|-------------|-------------------|--------|
| `x search users` | `/2/users/by` | GET |
| `x user followers` | `/2/users/:id/followers` | GET |
| `x user following` | `/2/users/:id/following` | GET |
| `x user block` | `/2/users/:id/blocking` | POST |
| `x user mute` | `/2/users/:id/muting` | POST |
| `x api <endpoint>` | Any `/2/*` endpoint | Any |

### Not yet planned

- Media upload (`/1.1/media/upload`)
- Spaces (`/2/spaces`)
- Direct Messages (`/2/dm_*` -- requires Pro tier)
- Compliance (`/2/compliance`)
