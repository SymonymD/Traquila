# Traquila

Retro-modern Hispanic tequila tracker built with SwiftUI + SwiftData.

## Architecture
- `Traquila/Models`: SwiftData models (`Bottle`, `PourEntry`, `BottlePhoto`) and domain enums.
- `Traquila/Stores`: CRUD orchestration (`BottleStore`, `PourStore`).
- `Traquila/Services`: pure/domain services (`InsightsService`, `ExportService`), settings, formatters, pacing timer.
- `Traquila/Views`: tab flows for Bottles, Log, Insights, and Settings.
- `Traquila/Components` + `Traquila/DesignSystem`: reusable UI components and theme tokens.

## How To Use
1. Open the **Bottles** tab and tap **Add Bottle**.
2. Fill at least the bottle name, then save.
3. Open the **Log** tab and tap **Quick Log**.
4. Select a bottle, choose amount/serve/context, then save the pour.

## Export
1. Open **Settings**.
2. Tap **Export My Data**.
3. Tap **Share Export File** to save or send the generated JSON file.

Notes:
- Export contains bottles + pours (no photo binary data).
- Photo filenames are included when available.
