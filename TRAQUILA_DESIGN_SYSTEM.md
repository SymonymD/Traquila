# Traquila Design System

Version: 1.0  
Based on current implementation in `Traquila/DesignSystem` and `Traquila/Components`.

## 1. Purpose
Traquila is a curated tequila cabinet and tasting journal with a retro-modern Hispanic aesthetic:
- Warm, tactile palette
- Refined typography
- Subtle decorative motifs (not busy)
- Strong readability in Light and Dark modes

This document is the source of truth for future UI iterations.

## 2. Design Principles
1. Content first: bottles, tastings, and insights should be immediately legible.
2. Warm restraint: use decorative details lightly; avoid visual noise.
3. Consistent hierarchy: title > heading > body > caption across all screens.
4. Material depth: cards and headers should feel layered but lightweight.
5. Accessibility by default: Dynamic Type, contrast, clear tap targets, VoiceOver labels.

## 3. Color Tokens
Defined in `Traquila/DesignSystem/TraquilaTheme.swift`.

### Brand Colors
- `agaveGreen` `#5C8D57`
- `terracotta` `#C96F4B`
- `marigold` `#DFAE3D`

### Adaptive Neutrals
- `charcoal`  
  - Light: `#1F2327`
  - Dark: `#F4EBDD`
- `parchment`  
  - Light: `#F8F2E8`
  - Dark: `#201B17`
- `tileLine`  
  - Light: `#D6C3A5`
  - Dark: `#5A4838`

### Usage Rules
- Use `terracotta` for primary highlights and action emphasis.
- Use `marigold` for ratings, badges, and accent moments.
- Use `parchment` and `tileLine` for soft backgrounds and borders.
- Never rely on pure white text over white fill controls.

## 4. Typography
Defined in `TraquilaTheme`:
- `titleFont()` = `.largeTitle` rounded bold
- `headingFont()` = `.title3` rounded semibold
- `bodyFont()` = `.body` rounded
- `captionFont()` = `.caption` rounded medium

Logo typography is serif/italic (`TraquilaLogoView`) and should remain unique to brand marks.

## 5. Layout Tokens
- Corner radius: `18`
- Card padding: `14`
- Standard vertical rhythm: 8 / 12 / 16 spacing steps
- Minimum tap target: 44x44pt

## 6. Motion
- Use restrained transitions: `opacity`, `slide`, `move + fade`.
- Use light haptics for key taps (save, continue, rating interactions).
- Avoid playful/bouncy animation styles.

## 7. Core Components
### `TraquilaCard`
File: `Traquila/Components/TraquilaCard.swift`
- Thin material background
- Decorative border (accent at 35% opacity)
- Soft shadow

### `ChipView`
File: `Traquila/Components/ChipView.swift`
- Capsule shape
- Caption typography
- Metadata affordance (icon + label)

### `StarRatingView`
File: `Traquila/Components/StarRatingView.swift`
- Supports half-stars
- Uses marigold as rating color
- Includes accessibility value string

### `EmptyStateView`
File: `Traquila/Components/EmptyStateView.swift`
- Supports SF Symbol or asset icon
- Dashed decorative border
- Clear guidance copy

### `TraquilaLogoView`
File: `Traquila/Components/TraquilaLogoView.swift`
- Auto-adapts logo ink/accent in dark mode
- Supports compact/full variants
- Accepts explicit `inkColor` override for special contexts (e.g., onboarding hero)

### `TalaveraHeaderBackground`
File: `Traquila/DesignSystem/TalaveraHeaderBackground.swift`
- Ultra-thin material base
- Warm gradient overlay
- Very subtle tile texture at bottom

## 8. Screen-Level Patterns
### Headers
- Keep brand logo visible on primary tabs (Cabinet, Log, Insights).
- Use talavera-inspired subtle texture, not dense patterns.

### Cards and Lists
- Use cards for featured content and summary metrics.
- Use compact list rows when high result density is needed.

### Forms
- Light control surfaces on warm backgrounds need explicit dark text/cursor styling.
- Always verify typed text contrast in both themes.

## 9. Theming Rules
1. Default app appearance mode is `System`.
2. Appearance options: `System`, `Light`, `Dark`.
3. Theme changes must propagate to all major flows (Onboarding + Tabs + Settings).
4. Dark mode should preserve warm brand character, not invert to cold grayscale.

## 10. Accessibility Requirements
- Dynamic Type support on all screens.
- VoiceOver labels for custom controls and tappable icons.
- Maintain contrast on translucent materials.
- Ensure icon-only actions have accessible labels and >= 44pt tap areas.

## 11. Copy Tone
- Refined, concise, cabinet/journal oriented.
- Avoid health-tracker framing.
- Use “tastings” / “experiences” wording over “pours” where context allows.

## 12. Implementation Guardrails
1. Extend `TraquilaTheme` tokens before introducing ad-hoc colors/fonts.
2. Reuse existing components before creating new one-off UI.
3. Keep decorative motifs below primary content contrast priority.
4. Validate both Light and Dark before merging UI changes.

## 13. Pre-Release UI Checklist
1. Light mode pass on iPhone 17 simulator.
2. Dark mode pass on iPhone 17 simulator.
3. Dynamic Type large sizes pass.
4. Empty state copy and layout pass.
5. VoiceOver labels pass for icon-only actions.
6. Onboarding form contrast pass (typed text + picker labels).
