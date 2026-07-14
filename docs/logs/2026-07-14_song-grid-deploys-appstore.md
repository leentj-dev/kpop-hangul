# Conversation Log - 2026-07-09 ~ 2026-07-14

## Summary
Multi-day session: reworked the whole song word-card system (4-measure → 1-measure
beat grid, 172→179 songs), built a hash-based auto-sync + daily cloud routine, added
many app features (swipe-to-seek, pull-to-refresh, Korean captions, dev-tools gating,
force update, light-theme fix), and shipped v39→v45 across Play alpha / iOS TestFlight
/ Firebase, culminating in re-submitting iOS 1.0.0 (build 45) to public App Store review.

## Issues & Solutions

### Word cards clustered at the front / too sparse
- **Problem**: cards bunched at song start; later parts had no synced cards. Then after
  the beat-grid switch, too few words.
- **Cause**: old selection picked ~20 words unevenly; 4-measure grid was too sparse.
- **Solution**: beat grid = one word per N measures, `interval_sec = N*4*60/BPM`, walking
  LRC lines evenly start→end. Settled on **1-measure** (4 beats): ~2512 → ~4903 words,
  avg 14.6 → 28.5. Regenerated all songs via ~22 parallel subagent batches.
- **Files**: all `app/assets/songs/*.json`, `.claude/commands/{newsong,syncsong}.md`

### Regenerated/translated songs didn't reach installed apps
- **Problem**: content edits (translations, offsets) never showed up on devices.
- **Cause**: `SongRepository._changed()` only compared wordCount/synced/youtubeId.
- **Solution**: added a content **hash** to `manifest.json` (`build_manifest.py`);
  `_changed` compares hash → any edit re-syncs. Pre-commit hook regenerates the manifest.
- **Files**: `app/scripts/build_manifest.py`, `.githooks/pre-commit`, `song_repository.dart`, `song.dart`

### intro offset changes didn't apply on the tuning device
- **Cause**: local SharedPreferences `offset_<id>` override always beat data introOffset.
- **Solution**: `syncRemote` clears the override when a song re-downloads (hash changed).
- **Files**: `song_repository.dart`

### Dev sync tools must not ship to production
- **Solution**: `kDevTools = bool.fromEnvironment('DEV_TOOLS')`; Firebase build passes
  `--dart-define=DEV_TOOLS=true`, Play/App Store builds omit it (verified via binary grep).
- **Files**: `app/lib/config/build_flags.dart`, `feed_screen.dart`, `song_screen.dart`

### Light theme unreadable
- **Cause**: song title/word-count hardcoded `Colors.white`; artist used a light pastel accent.
- **Solution**: use `onSurface`; `SongTheme.accentOn(isDark)` darkens accents for light mode.
- **Files**: `feed_screen.dart`, `utils/themes.dart`

### iOS stuck 5 days in "Waiting for Review" (build 35)
- **Cause 1**: unanswered social-media age-rating question (user fixed in App Info).
- **Cause 2 (build swap)**: attaching new build 45 → submit failed because build 45's
  **export compliance** (`usesNonExemptEncryption`) was unanswered.
- **Solution**: via ASC API — deleted old submission, PATCHed build→45, set
  `usesNonExemptEncryption=false`, created reviewSubmission + item, PATCHed submitted=true.
  Result: 1.0.0 WAITING_FOR_REVIEW on build 45.

### Other
- YouTube CC defaulted to English → set `captionLanguage:'ko'` (only works if video has KR track).
- Swipe the word deck now seeks the video (`onPageChanged` → `_seekToWord`, guarded by `_userScrolling`).
- Pull-to-refresh added to the feed (RefreshIndicator → syncRemote).
- Force update: RC `min_version` + blocking dialog (package_info_plus + url_launcher).
- Removed the redundant per-thumbnail SYNC badge (all songs synced now).

## Decisions Made
- **1-measure** grid is the standard (skills + method doc updated).
- Dev tools ship only in Firebase builds, never Play/App Store.
- iOS goes to public review; **Android stays in alpha** (Google 20-tester/14-day rule for production).
- Store IDs: Android `dev.leentj.kpop_hangul`, iOS App Store id `6788620417`, Firebase Android app `1:164859236716:android:9d82e4ad1fd7764eb96349`.

## TODO / Follow-up
- **Cloud routine still on the OLD grid** — it can't be updated from this session (GitHub not
  connected on the post-`/login` account; original owner account needed). ~15 routine-added
  songs since the 1-measure regen are sparse and should be regenerated to 1-measure.
- iOS review result (build 45) — expect 24-48h.
- Android production launch pending Google testing requirements.
- Social-media age-rating: final Apple deadline 2026-09-07.
