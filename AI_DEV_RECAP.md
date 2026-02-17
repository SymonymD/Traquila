# AI Dev Recap

Last updated: 2026-02-17 (cabinet interactions + pour balance accounting + onboarding motion + feedback + storage cleanup)
Project: `Traquila` (Xcode 26.2, SwiftUI + SwiftData)

## Purpose
This file tracks implementation progress between AI sessions so work can continue safely if context resets or another agent takes over.

## Current Status
- MVP app structure is implemented and pushed to `origin/main`.
- SwiftUI Preview crash fixed by injecting required environment dependencies in preview context.
- Full first-launch onboarding flow implemented with coordinator gating, persisted preferences, optional permission step, and personalization handoff.
- Discover workflow implemented: market-style search plus local-library matches and a persisted wishlist.
- Discover upgraded to live network search provider with static fallback for reliability.
- Logo redesigned to a pen-and-ink style and applied to onboarding + bottles header.
- Bottles screen redesigned: top half Discovery (search + Popular cards), bottom half Library list.
- Discover tab removed; Bottles renamed to Cabinet and now serves as primary search/discovery + library hub.
- Cabinet header updated so Traquila logo and add (+) action are aligned in the same top row.
- Search result actions updated: wishlist button shows checkmark after save, log-pour action uses a plus icon.
- Cabinet tab icon fixed to use PNG asset scales in `CabinetTabIcon.imageset` (1x/2x/3x) to avoid oversized rendering.
- All `+` actions updated to outline-style (no fill); header `+` enlarged to match the Traquila wordmark scale.
- Cabinet results now support display toggle: `List` or `Cards` (3-column grid) for both Popular and Search Results.
- Discovery source strategy implemented for cost control:
  - `Curated Local` (default, lowest cost)
  - `Hybrid (Live + Local)`
  - `Premium Catalog` (stub for future paid provider)
- Insights fully reworked into an Experience Dashboard with sticky multi-filter chips, Top Experience hero, Top Bottles, Top Experiences, Preference Snapshot, and filtered trend chart.
- Log and Insights headers now persist Traquila branding in sticky header areas with reduced top spacing and inline title mode.
- Log filter bar date control changed from ambiguous toggle to calendar icon reveal/hide behavior.
- Pour logging now supports optional photo upload (PhotosPicker), preview, removal, persistence, and detail display.
- Existing tasting logs are now explicitly editable from the detail screen via an `Edit` button.
- Debug-only mock data seeder added for quick market/demo testing when database is empty.
- Added new onboarding step: `Create Your Profile` (after How It Works, before Preferences).
- New `UserProfile` SwiftData model persists:
  - display name
  - experience level
  - preferred styles
  - typical enjoyment contexts
  - cabinet intent
  - timestamps
- Onboarding now validates required profile fields (display name + experience level) for Continue, with explicit skip defaults.
- Onboarding flow simplified to 3 steps only: Welcome -> How It Works -> Create Profile.
- Removed legacy onboarding screens (`Your Preferences`, `Personalize`, and notifications prompt) to reduce friction.
- `Skip for now` on profile step is now centered at the bottom for cleaner CTA hierarchy.
- Settings now includes Profile section to view/edit profile fields and reset onboarding with optional profile clear.
- Dark mode now applies immediately when changed in Settings, and theme colors are adaptive for light/dark palettes.
- Theme enforcement hardened across app root/coordinator; runtime interface style is now applied from `AppSettings` and app-level routing uses explicit theme propagation.
- Added and then removed temporary Theme Debug section in Settings after diagnosing theme state vs rendering.
- Settings `Responsible Use` section removed per product direction.
- Onboarding form contrast polished:
  - profile text field now forces dark typed text on light field background
  - experience-level option cards now use explicit dark text on light cards
  - onboarding primary button text contrast fixed against light button backgrounds
- Added `TRAQUILA_DESIGN_SYSTEM.md` as the UI source of truth for future iterations.
- Core flows are functional end-to-end:
  - Bottle library (CRUD, rating, notes, photos)
  - Pour/tasting logging (CRUD, timeline, filtering/search, optional photo)
  - Experience dashboard (filtered rankings + trend + preference snapshot)
  - Settings (theme, units, discovery source mode, responsible-use toggles, JSON export, import stub)
- Metadata file pollution cleanup completed (`._*`), and ignore rules added.
- Cabinet library filters finalized to `Cellar / Top Rated / Recent / Wishlist`; source selection added in Log bottle picker (`My Bottle` vs `At Restaurant`).
- Library pane on Cabinet now supports drag-resize between ~1/3 and ~2/3 screen height; focusing search collapses back to ~1/3.
- Library pane visual polish: rounded top-left/top-right corners and drag handle affordance.
- Wishlist icon styling in Popular/Search results changed to plain icon (no filled/bordered background).
- Pour volume accounting implemented: pours from `My Bottle` now decrement bottle balance (`fillLevelPercent`) and edits/deletes correctly rebalance.
- Onboarding `How It Works` upgraded with restrained motion system (staggered fade/slide, floating icons, material cards) plus auto-advance carousel (~4s) that pauses during user interaction.
- Settings now includes a `Feedback` section:
  - `Send Feedback` opens prefilled email template (version/device/profile context).
  - `Copy Feedback Template` copies structured report text to clipboard.
- Verified no direct MapKit Snapshot API usage in Traquila source (`MKMapSnapshotter`/MapKit import absent); observed snapshot service process is simulator-level system runtime activity.
- Local storage audit + cleanup performed:
  - Cleared Xcode Previews cache, DerivedData, iOS DeviceSupport, and CoreSimulator caches.
  - Reclaimed ~24GB+ disk.
  - Remaining large footprint primarily in CoreSimulator devices/runtimes.

## Architecture Snapshot
- `Traquila/Models`
  - `Bottle`, `PourEntry`, `BottlePhoto`, `WishlistItem`, `UserProfile`
  - Domain enums for bottle type, region, serve style, context, etc.
- `Traquila/Stores`
  - `BottleStore` (CRUD + photo handling)
  - `PourStore` (CRUD + cellar balance adjustments on create/update/delete)
- `Traquila/Services`
  - `InsightsService` (aggregations/trends + sample helpers)
  - `DiscoverService` (source strategy: curated/hybrid/premium-stub)
  - `MockDataSeeder` (debug-only sample bottles/tastings bootstrap)
  - `ExportService` (JSON export)
  - `AppSettings`, `PacingTimerService`, `Formatters`
- `Traquila/Views`
  - Cabinet (formerly Bottles): integrated search/popular results + library/wishlist filters, plus detail/edit
  - Log: timeline/add/detail (+ photo support, explicit detail edit)
  - Insights: Experience Dashboard (filter chips, ranked sections, trend)
  - Settings: app/data options + editable profile + feedback entry points
- `Traquila/Components` + `Traquila/DesignSystem`
  - Theme, reusable cards/chips/star rating/empty state/talavera header motif
  - Design reference doc: `TRAQUILA_DESIGN_SYSTEM.md`
- App shell
  - `Traquila/TraquilaApp.swift` sets up SwiftData container and global theme mode
  - `Traquila/App/RootTabView.swift` provides 4-tab navigation

## Recent Commit History
1. `0a1cc70` Traquila: add SwiftData models and persistence foundation
2. `c832259` Traquila: build bottle library flows and reusable UI components
3. `00ec9ab` Traquila: implement pour logging timeline and detail flows
4. `f1f35ae` Traquila: add insights aggregations charts and pacing timer
5. `b780d44` Traquila: add settings controls and JSON data export
6. `449fbeb` Traquila: polish docs tests and metadata ignore rules

## Validation Notes
- Build check succeeded:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build check re-run after onboarding/theme changes succeeded:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build re-run multiple times after theme and onboarding contrast patches; latest run succeeded:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build succeeded after pour-balance accounting changes:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build succeeded after Cabinet resizable Library panel + top corner rounding:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build succeeded after onboarding animation + autoplay updates:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Build succeeded after Settings feedback section implementation:
  - `xcodebuild -scheme Traquila -destination 'platform=iOS Simulator,name=iPhone 17' build`
- Environment note during cleanup: `simctl` temporarily reported CoreSimulatorService connection invalid; cache cleanup still completed, but unavailable-device pruning should be rerun after reboot.
- Unit test target compiles; simulator test execution was unstable/hanging in this environment, so full automated run completion was not consistently captured.

## Repo Hygiene
- `.gitignore` includes:
  - `._*`
  - `.DS_Store`
- Remote configured:
  - `origin https://github.com/SymonymD/Traquila.git`
- Branch tracking:
  - `main` -> `origin/main`

## Known Gaps / Follow-up Candidates
- Confirm simulator test execution stability and capture a clean `test` pass log.
- Validate onboarding transitions and sheet handoff in live simulator UX pass.
- Wire a real paid tequila catalog/provider into `Premium Catalog` mode when demand validates.
- Consider switching hybrid live provider from generic product search to tequila-specific source when available.
- Optionally use profile values to pre-seed Insights filters and personalize cabinet headings across tabs.
- Replace hardcoded feedback recipient (`hello@traquila.app`) with configurable app setting or environment-driven value before wider distribution.
- Optional enhancement: implement local notification permission flow for hydration reminders.
- Optional enhancement: make import flow functional (currently disabled stub by design).
- Optional enhancement: add additional tests for export formatting and search/filter logic.

## Update Protocol (for future AI sessions)
When making changes, always update this file in the same commit:
1. Update `Last updated` date.
2. Add a short bullet under `Current Status`.
3. Append new commit(s) to `Recent Commit History`.
4. Record build/test outcomes in `Validation Notes`.
5. Add/remove items in `Known Gaps / Follow-up Candidates` as needed.
