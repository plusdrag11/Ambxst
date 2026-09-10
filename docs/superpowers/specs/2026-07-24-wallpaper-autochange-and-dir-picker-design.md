# Wallpaper Autochange & Directory Picker

**Date:** 2026-07-24
**Status:** Approved

## Overview

Add two features to ambxst's wallpaper system:
1. **Autochange (Slideshow)** — Timer-based wallpaper rotation with configurable interval and mode
2. **Directory Picker** — File dialog to browse and select wallpaper directories from the dashboard

## Feature 1: Autochange (Slideshow)

### Config Keys (in `wallpapers.json` adapter)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `autochangeEnabled` | bool | `false` | Enable/disable autochange |
| `autochangeInterval` | int | `1800000` | Interval in milliseconds (30 min) |
| `autochangeMode` | string | `"shuffle"` | `"shuffle"` or `"sequential"` |

### Implementation

**`Wallpaper.qml`:**
- Add `Timer` with `interval: wallpaperConfig.adapter.autochangeInterval` and `running: wallpaperConfig.adapter.autochangeEnabled`
- On trigger: call `nextWallpaper()` (sequential) or pick random from unshown list (shuffle)
- Maintain `_shuffledIndices` array for shuffle mode; reshuffle when exhausted
- Reset timer on manual wallpaper change so autochange doesn't interrupt user choice
- Pause timer when dashboard wallpaper tab is open (`GlobalStates.dashboardOpen`)

**`WallpapersTab.qml`:**
- Add "Auto" toggle button following existing OLED/Tint checkbox pattern
- When enabled, show interval selector and mode selector
- Use same `StyledRect` variant pattern (`"pane"` / `"focus"`) as existing toggles

### UI Layout

Top bar order: `[Monitor] [OLED] [Tint] [Auto] [Scheme Selector]`

When Auto is enabled, a secondary row appears below the filter bar with:
- Interval dropdown: 5m / 15m / 30m / 1h
- Mode toggle: Shuffle / Sequential

## Feature 2: Directory Picker

### Implementation

**`WallpapersTab.qml`:**
- Add a folder icon button in the top bar (left of search or in the toggle row)
- On click, open a `FileDialog` (QtQuick.Dialogs) filtered for image files
- On directory selection, update `wallpaperConfig.adapter.wallPath`
- The existing `onWallPathChanged` handler in `Wallpaper.qml` handles the rescan

### UI

A small `StyledRect` button with a folder icon, matching the existing toggle button style (48px height, `pane` variant).

## Files to Modify

1. `modules/widgets/dashboard/wallpapers/Wallpaper.qml` — Add autochange Timer, adapter properties, shuffle logic
2. `modules/widgets/dashboard/wallpapers/WallpapersTab.qml` — Add Auto toggle UI, directory picker button
3. `config/Config.qml` — Add autochange properties to wallpaper adapter (if not handled by Wallpaper.qml's local adapter)

## Conventions

- All UI follows existing ambxst toggle pattern (StyledRect + checkbox + keyboard nav)
- Config persisted via `wallpapers.json` FileView/JsonAdapter
- No hardcoded colors/sizes — use `Config.theme.*`, `Colors.*`, `Styling.*`
- Use `StyledRect` with `"pane"` variant for containers
