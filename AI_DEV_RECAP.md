# AI Dev Recap

Last updated: 2026-02-16 (experience dashboard + discovery strategy + tasting photo support)
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
- Core flows are functional end-to-end:
  - Bottle library (CRUD, rating, notes, photos)
  - Pour/tasting logging (CRUD, timeline, filtering/search, optional photo)
  - Experience dashboard (filtered rankings + trend + preference snapshot)
  - Settings (theme, units, discovery source mode, responsible-use toggles, JSON export, import stub)
- Metadata file pollution cleanup completed (`._*`), and ignore rules added.

## Architecture Snapshot
- `Traquila/Models`
  - `Bottle`, `PourEntry`, `BottlePhoto`, `WishlistItem`
  - Domain enums for bottle type, region, serve style, context, etc.
- `Traquila/Stores`
  - `BottleStore` (CRUD + photo handling)
  - `PourStore` (CRUD)
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
  - Settings: app and data options
- `Traquila/Components` + `Traquila/DesignSystem`
  - Theme, reusable cards/chips/star rating/empty state/talavera header motif
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
