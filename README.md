# Party Game

A pass-and-play party game app for one device. Add your friends in the lobby,
pick a game, pass the phone around, and track scores across the whole party.

## Games

| Game | What happens |
| --- | --- |
| **Truth or Dare** | One player asks, another picks truth or dare. Rules for repeat askers and round coverage are configurable. Custom prompts can be added mid-game. |
| **Imposter** | Everyone gets a word; imposters only get the category. Give clues, then vote out the imposter. Supports multiple imposters. |
| **Question Imposter** | Everyone sees a question except the imposters, who must bluff an answer. Vote on the most suspicious answer. |
| **Charades** | One player acts out a word. Play everyone-for-themselves or split into two teams. Timed by default. |

All games support a configurable number of rounds and a timed or round-based
mode. Scores accumulate on a shared party scoreboard and are shown between
games and on the final podium screen.

## Getting started

```bash
flutter pub get
flutter run
```

Requirements: Flutter 3.44+ / Dart 3.12+.

Run checks:

```bash
flutter analyze
flutter test
```

## How it works

- **Party flow** — `PartyTypeScreen` → `LobbyScreen` → `GameSelectScreen` →
  `GameSettingsScreen` → `GamePlayScreen` → final standings.
- **Plugin architecture** — each game lives in `lib/ui/features/games/<id>/`
  with a `plugin.dart` (metadata, settings UI, screen factory), `logic.dart`
  (state machine and scoring, extends `GameLogic`), and `screen.dart` (UI that
  listens to the logic).
- **Content** — JSON files in `content/` are also bundled under
  `assets/content/` and cached in Hive on first launch, so games work offline.
  `ContentService` can optionally refresh from a configurable GitHub repo via
  `manifest.json` hashes.
- **State** — Riverpod for app state, Hive for the content cache and scoreboard.

LAN multiplayer is intentionally marked "coming soon": the connection layer is
abstracted behind `ConnectionService`, but only pass-and-play is wired up today.

## Content data

Starting content ships with the app:

- 67 truths and 66 dares
- 15 imposter categories with 16–24 words each
- 52 question-imposter questions
- 140 charades words/phrases

Add or edit entries in `content/*.json`, mirror them into `assets/content/`,
then update the SHA-256 hashes in `content/manifest.json`.
