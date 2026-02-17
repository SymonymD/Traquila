# Traquila

Retro-modern Hispanic tequila tracker built with SwiftUI + SwiftData.

## Design System
- Canonical UI reference: `TRAQUILA_DESIGN_SYSTEM.md`
- Use this doc for tokens, component usage, theming behavior, and accessibility guardrails before introducing new UI patterns.

## Architecture
- `Traquila/Models`: SwiftData models (`Bottle`, `PourEntry`, `BottlePhoto`, `WishlistItem`) and domain enums.
- `Traquila/Stores`: CRUD orchestration (`BottleStore`, `PourStore`).
- `Traquila/Services`: pure/domain services (`InsightsService`, `ExportService`, `DiscoverService`), settings, formatters, pacing timer.
- `Traquila/Views`: tab flows for Bottles, Log, Discover, Insights, and Settings.
- `Traquila/Onboarding`: 5-step onboarding flow, permission prompt, and personalization.
- `Traquila/App/AppCoordinatorView.swift`: launch gate that routes to onboarding or main tabs from persisted onboarding state.
- `Traquila/Components` + `Traquila/DesignSystem`: reusable UI components and theme tokens.

## How To Use
1. Open the **Bottles** tab and tap **Add Bottle**.
2. Fill at least the bottle name, then save.
3. Open the **Log** tab and tap **Quick Log**.
4. Select a bottle, choose amount/serve/context, then save the pour.

## Discover + Wishlist
1. Open **Discover** and search by bottle name, brand, or NOM.
2. Review both:
   - matches already in your local library
   - market discovery results (live query)
3. From market results:
   - tap **Add to Library** to create a new bottle immediately
   - tap **Save to Wishlist** to keep a “want to try” item
4. In **Want to Try**, swipe a wishlist item to **Add** (move to library) or **Delete**.

Notes:
- Discover uses a live provider first (Open Food Facts search API) and falls back to curated local catalog results if live search is unavailable or empty.
- Results are debounced and loaded asynchronously via `DiscoverViewModel`.

## Export
1. Open **Settings**.
2. Tap **Export My Data**.
3. Tap **Share Export File** to save or send the generated JSON file.

Notes:
- Export contains bottles + pours (no photo binary data).
- Photo filenames are included when available.

## Onboarding
- First launch: `AppCoordinatorView` checks `AppSettings.onboardingComplete`.
  - `false` -> `OnboardingFlowView`
  - `true` -> main tab app (`RootTabView`)
- Preferences collected during onboarding are saved through `SettingsCoordinator.apply(...)` into `AppStorage`-backed `AppSettings`.
- Notification authorization is requested only when responsible nudges require pacing/hydration reminders.
- Optional “Add first bottle now” opens `BottleEditView` after onboarding finishes.
- Settings includes **Reset Onboarding**, which clears the completion flag so onboarding appears again on next launch.
