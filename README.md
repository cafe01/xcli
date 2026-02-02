# xcli

The `gh` equivalent for X.com. Same mental model as web/mobile, expressed as CLI subcommands.

```
x <command> [subcommand] [flags]
```

Built on X API v2 with OAuth 2.0 PKCE. Supports multiple accounts, human-readable and JSON output, and is designed to work well for both humans and AI agents.

**Version**: 0.1.0 | **SDK**: Dart 3.8+ | **License**: See repository

## Quick start

```bash
# Build from source
cd packages/xcli
dart compile exe bin/x.dart -o x

# Move to PATH
mv x /usr/local/bin/x

# Authenticate (opens browser)
export X_CLIENT_ID="your-client-id"
x auth login

# Verify
x auth status
x user me

# Read your timeline
x timeline home

# Post a tweet
x tweet create "Hello from the command line"
```

## Command reference

### Core commands

| Command | Description | Status |
|---------|-------------|--------|
| `x tweet view <id>` | View a tweet by ID | Implemented |
| `x tweet create <text>` | Post a new tweet | Implemented |
| `x tweet delete <id>` | Delete a tweet by ID | Implemented |
| `x tweet like <id>` | Like a tweet | Implemented |
| `x tweet unlike <id>` | Unlike a tweet | Implemented |
| `x tweet retweet <id>` | Retweet a tweet | Implemented |
| `x tweet unretweet <id>` | Undo a retweet | Implemented |
| `x tweet bookmark <id>` | Bookmark a tweet | Implemented |
| `x tweet unbookmark <id>` | Remove a bookmark | Implemented |
| `x tweet bookmarks` | List bookmarked tweets | Implemented |
| `x tweet reply <id> <text>` | Reply to a tweet | Coming soon |
| `x tweet quote <id> <text>` | Quote-tweet | Coming soon |
| `x tweet thread <id>` | View a tweet thread | Coming soon |

### User commands

| Command | Description | Status |
|---------|-------------|--------|
| `x user view <username>` | View a user profile | Implemented |
| `x user me` | View your own profile | Implemented |
| `x user follow <username>` | Follow a user | Implemented |
| `x user unfollow <username>` | Unfollow a user | Implemented |
| `x user followers <username>` | List a user's followers | Coming soon |
| `x user following <username>` | List who a user follows | Coming soon |
| `x user block <username>` | Block a user | Coming soon |
| `x user mute <username>` | Mute a user | Coming soon |

### Timeline commands

| Command | Description | Status |
|---------|-------------|--------|
| `x timeline home` | View your home timeline | Implemented |
| `x timeline mentions` | View tweets mentioning you | Implemented |
| `x timeline user <username>` | View a user's timeline | Implemented |

### Search commands

| Command | Description | Status |
|---------|-------------|--------|
| `x search tweets <query>` | Search recent tweets | Implemented |
| `x search users <query>` | Look up users by username | Coming soon |

### Auth commands

| Command | Description | Status |
|---------|-------------|--------|
| `x auth login` | Log in via OAuth 2.0 PKCE | Implemented |
| `x auth logout [account]` | Log out (revoke credentials) | Implemented |
| `x auth status` | Show authentication status | Implemented |
| `x auth switch <account>` | Switch active account | Implemented |

### Plumbing commands

| Command | Description | Status |
|---------|-------------|--------|
| `x api <endpoint>` | Raw X API v2 requests | Coming soon |
| `x config get <key>` | Get a config value | Coming soon |
| `x config set <key> <value>` | Set a config value | Coming soon |
| `x config list` | List all config values | Coming soon |
| `x dm` | Direct messages | Coming soon |
| `x list` | Curated lists | Coming soon |

## Authentication

xcli uses OAuth 2.0 Authorization Code with PKCE (no client secret required).

### Setup

1. Create a developer app at [developer.x.com](https://developer.x.com/en/portal)
2. Set the callback URL to `http://localhost:8914/callback`
3. Copy your Client ID

```bash
# Set client ID (env var or flag)
export X_CLIENT_ID="your-client-id"
x auth login

# Or pass directly
x auth login --client-id "your-client-id"
```

### Multi-account

```bash
# Login with named accounts
x auth login --account personal
x auth login --account bot

# Switch between them
x auth switch bot
x auth status

# Use a specific account for one command
x --account personal timeline home
```

### Token storage

Tokens are stored at `~/.config/xcli/accounts.json`. The file contains access tokens, refresh tokens, expiry timestamps, and granted scopes. Tokens are automatically refreshed 5 minutes before expiry.

## Output modes

### Human-readable (default)

```bash
x tweet view 1234567890
```

```
@elonmusk (Elon Musk) [checkmark]

The future of social media is here

2h ago  1.5K Likes  234 Retweets  89 Replies
```

### JSON output

```bash
x tweet view 1234567890 --json
```

```json
{
  "data": {
    "id": "1234567890",
    "text": "The future of social media is here",
    "author_id": "44196397",
    "created_at": "2026-01-31T12:00:00.000Z",
    "public_metrics": {
      "like_count": 1500,
      "retweet_count": 234,
      "reply_count": 89
    }
  },
  "includes": {
    "users": [
      {
        "id": "44196397",
        "name": "Elon Musk",
        "username": "elonmusk",
        "verified": true
      }
    ]
  }
}
```

### Disabling color

```bash
x --no-color timeline home    # flag
NO_COLOR=1 x timeline home    # env var (https://no-color.org)
```

## Examples

```bash
# View a user profile
x user view torvalds

# Search for recent tweets
x search tweets "dart programming"

# Post a reply
x tweet create "Great thread!" --reply-to 1234567890

# Post a quote tweet
x tweet create "This is important" --quote 1234567890

# Like and bookmark a tweet
x tweet like 1234567890
x tweet bookmark 1234567890

# View your bookmarks as JSON (useful for piping)
x tweet bookmarks --json | jq '.data[].text'

# Check who you are logged in as
x user me --json | jq '.data.username'

# View mentions for a bot account
x --account mybot timeline mentions
```

## Global flags

| Flag | Description |
|------|-------------|
| `--version` | Print the CLI version |
| `-a, --account <name>` | Use a specific authenticated account |
| `--verbose` | Enable verbose output |
| `--no-color` | Disable colored output |

The `NO_COLOR` environment variable is also respected per the [no-color.org](https://no-color.org) standard.

## Development

```bash
# Run tests
dart test packages/xcli

# Run analyzer
dart analyze packages/xcli

# Build executable
dart compile exe packages/xcli/bin/x.dart -o x
```

### Project structure

```
packages/xcli/
  bin/x.dart                  # Entry point
  lib/src/
    api/
      x_api.dart              # Abstract API interface
      raw_http_x_api.dart     # Concrete HTTP implementation
      x_api_exception.dart    # Typed exceptions (401, 404, 429)
    auth/
      oauth_flow.dart         # OAuth 2.0 PKCE flow
      token_store.dart        # Multi-account token persistence
      token.dart              # Token data class
      pkce.dart               # PKCE challenge generation
      authenticated_client.dart # Auto-refreshing HTTP client
    cli/
      x_runner.dart           # CommandRunner setup, global flags
      format.dart             # ANSI colors, formatters
      commands/
        tweet/                # Tweet CRUD + engagement
        user/                 # User profiles + relationships
        timeline/             # Home, mentions, user timelines
        search/               # Tweet and user search
        auth/                 # Login, logout, status, switch
        config/               # Configuration (stub)
        api/                  # Raw API escape hatch (stub)
        dm/                   # Direct messages (stub)
        list/                 # Curated lists (stub)
  test/                       # Unit tests with mocktail
```

## Architecture

Commands depend on the `XApi` abstract interface, never on a concrete implementation. `RawHttpXApi` is the production implementation using `package:http`. `AuthenticatedClient` wraps the HTTP client with Bearer token injection and automatic refresh. This design allows injecting mock APIs for testing and swapping implementations without touching command code.

The `CommandRunner` pattern from `package:args` provides subcommand routing, flag parsing, and usage help generation.

## Status

**Implemented** (21 commands): tweet view, create, delete, like, unlike, retweet, unretweet, bookmark, unbookmark, bookmarks; user view, me, follow, unfollow; timeline home, mentions, user; search tweets; auth login, logout, status, switch.

**Coming soon** (14 commands): tweet reply, quote, thread; user followers, following, block, mute; search users; api; config get, set, list; dm; list.
