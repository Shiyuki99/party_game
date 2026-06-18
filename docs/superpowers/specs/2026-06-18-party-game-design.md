# Party Game App — Design Spec

## Overview
Multiplayer party game app with 4 initial games. Supports Pass&Play (single device) and LAN P2P (WebRTC over QR code signaling). Plugin-based game architecture.

## Architecture

### Layers
- **UI** — MVVM with Riverpod (state management)
- **Data** — Repository pattern (Hive for local, GitHub for content)
- **Connection** — Abstract `ConnectionService` interface, WebRTC v1 impl

### Networking (LAN/P2P)
- `ConnectionService` abstract class with `send`, `broadcast`, `onMessage`, `onPlayerJoin`, `onPlayerLeave`
- v1: WebRTC with QR code signaling (host's SDP offer encoded in QR)
- Future swaps: swap `ConnectionService` impl, no app changes needed
- Pass&Play uses a local `PassPlayConnectionService` (in-process message bus)

### Content System
- GitHub public repo: `Shiyuki99/party-game-content`
- Directory: `content/{game_id}.json` (flat, outside code)
- On launch: `ContentManager` checks for updates via HTTP conditional GET
- Hive caches per-game content
- Configurable repo URL in app settings
- Bundled fallback assets for offline

### Theme System
- Single `AppTheme` class in `lib/ui/core/theme/app_theme.dart`
- Colors, typography, input field styles, spacing
- All games + screens consume shared theme
- Shared widgets in `lib/ui/core/widgets/`

### Game Plugin System

```dart
abstract class GamePlugin {
  String get id;
  String get name;
  IconData get icon;
  SettingsModel get defaultSettings;
  Widget buildSettingsScreen(SettingsModel settings);
  Widget buildPlayScreen(GameContext context);
}
```

- Registry: `final gamePlugins = <GamePlugin>[...];`
- Each plugin in its own folder under `ui/features/games/`

### Scoreboard
- In-memory Riverpod state (session-scoped)
- Persisted to Hive on app background
- Reset on "New Party" or manual reset
- Flat: `{playerId, name, score}`
- Scoring rules per-game, board is universal

## Party Flow

1. **PartyTypeScreen** — Choose Pass&Play or LAN
2. **LobbyScreen** — Add players (P&P) or join via QR (LAN)
3. **GameSelectScreen** — Pick a game from plugin grid
4. **GameSettingsScreen** — Configure time, rounds, host mode, etc.
5. **GamePlayScreen** — Runs the game plugin

## Games (4 initial)

### Truth or Dare
- Turns: spin 2 random players (asker + answerer)
- Answerer picks truth or dare
- Rules: no repeat asker, everyone questioned once per round, last player can't ask
- All configurable in settings
- Content: truth/dare lists

### Imposter
- Everyone gets a word, one gets imposter
- Imposter gets category hint
- Players say one related word in turns
- Vote out the most suspicious
- Content: word lists by category

### Question Imposter
- Everyone gets a question; one is imposter
- Submit answers, reveal actual question
- Vote based on suspicious answers
- Content: question lists

### Charades
- One player emotes a word, others guess
- Modes: solo (first to guess wins), team-based
- Opposing team can give word in team mode
- Content: word lists by category

## Game Attributes (all configurable)
- Round time limit
- Number of rounds
- Host mode (fixed / rotating)
- Custom text input override
- Each game exposes its settings via `buildSettingsScreen`

## Tech Stack
- Flutter 3.44+ / Dart 3.12+
- State: Riverpod
- Local storage: Hive
- P2P: flutter_webrtc + QR (via qr_flutter + mobile_scanner)
- HTTP: dart:io HttpClient or http package
- Routing: go_router
