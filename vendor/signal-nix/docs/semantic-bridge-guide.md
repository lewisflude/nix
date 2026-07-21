# Semantic Bridge Guide

**Complete guide to using Signal colors in your Nix modules**

The semantic bridge (`lib/semantic.nix`) is the **exclusive interface** for accessing Signal colors. This guide covers everything from basic usage to advanced patterns.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Why Semantic Bridge?](#why-semantic-bridge)
- [Complete Reference](#complete-reference)
- [Advanced Usage](#advanced-usage)
- [Rules & Validation](#rules--validation)
- [Migration Guide](#migration-guide)

---

## Quick Start

### Basic Usage

```nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;  # "light" or "dark"
in {
  # Use semantic bridge
  programs.app.colors = {
    background = (semantic.core "background" mode).hex;
    foreground = (semantic.core "foreground" mode).hex;
    error = (semantic.status "error" mode).hex;
  };
}
```

### Color Object Properties

Every semantic reference returns a color object:

```nix
color = semantic.core "background" mode;

color.hex        # "#1a1b1e"       - Hex with #
color.hexRaw     # "1a1b1e"        - Hex without #
color.rgb        # "26, 27, 30"    - RGB comma-separated
color.l          # 0.15            - Lightness (0-1)
color.c          # 0.01            - Chroma (0-0.4)
color.h          # 240             - Hue (0-360)
color.description # "..."          - Human description
```

### Cheat Sheet

```nix
# Setup (once per module)
{ signalLib, semantic, ... }: let
  mode = signalLib.resolveThemeMode cfg.mode;
in

# Get a color (one-liner)
bg = (semantic.core "background" mode).hex;

# Common colors
background = semantic.core "background" mode;
text = semantic.core "foreground" mode;
error = semantic.status "error" mode;
success = semantic.status "success" mode;
link = semantic.text "link" mode;
```

---

## Why Semantic Bridge?

The semantic bridge provides a **stable, intention-based API** for colors.

### ✅ Benefits

1. **Stability** - Palette structure can change without breaking modules
2. **Semantics** - Colors named by purpose (`"background"`) not path (`"surface-base"`)
3. **Maintainability** - One place to update color mappings
4. **Type Safety** - Better error messages with suggestions
5. **Discoverability** - Clear categories (core, ui, syntax, etc.)
6. **Testing** - Single point to validate color usage

### ❌ Problems with Direct Access

```nix
# ❌ BAD: Direct palette access
background = palette.tonal.dark."surface-base".hex;

# Problems:
# - Breaks if palette.tonal structure changes
# - "surface-base" doesn't convey intent
# - No guidance if name is wrong
# - Duplicates color logic across modules
```

```nix
# ✅ GOOD: Semantic bridge
background = (semantic.core "background" mode).hex;

# Benefits:
# - Stable API even if palette changes
# - "background" clearly states intent
# - Helpful error if name is wrong
# - Single source of truth
```

### Core Principle

> **All color access MUST go through `lib/semantic.nix`**

The semantic bridge is the authoritative source for:
- **Signal color palette** → `signal-palette` flake
- **Semantic mappings** → `semanticBridge` definition
- **Color resolution** → Helper functions

**Upstream source**: Based on `signal-palette/semantic-bridge.json v1.1.0`

---

## Complete Reference

### Available Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| `core` | Fundamental UI | background, foreground, cursor |
| `ui` | Panels, borders, states | panel-background, element-hover |
| `text` | Text hierarchy | primary, secondary, tertiary |
| `terminal` | ANSI colors | ansi-red, ansi-green, ansi-blue |
| `editor` | Editor-specific UI | line-number, gutter-background |
| `syntax` | Code highlighting | keyword, function, string |
| `markup` | Markdown/docs | heading, link, code |
| `vcs` | Version control | added, modified, deleted |
| `status` | Indicators | error, warning, success, info |
| `multiplayer` | Collaboration | player-1 through player-8 |

---

### 🎨 core - Fundamental UI Colors

Essential colors present in every application.

| Name | Purpose | Example Use |
|------|---------|-------------|
| `background` | Main background | Terminal bg, editor bg |
| `foreground` | Main text | Terminal fg, editor text |
| `cursor` | Cursor/caret | Text cursor, selection indicator |
| `selection-bg` | Selected text background | Text selection |
| `selection-fg` | Selected text foreground | Text selection |
| `focus` | Focus indicator | Active element border |

**Usage:**
```nix
bg = semantic.core "background" mode;
fg = semantic.core "foreground" mode;
cursor = semantic.core "cursor" mode;
```

---

### 🎯 ui - Panels, Borders, States

Common interactive UI elements.

| Name | Purpose |
|------|---------|
| `panel-background` | Panel/sidebar background |
| `panel-border` | Panel borders |
| `element-hover` | Hover state |
| `element-active` | Active/pressed state |
| `element-selected` | Selected item |
| `element-disabled` | Disabled state |
| `status-bar-background` | Status bar bg |
| `tab-active-background` | Active tab |
| `tab-inactive-background` | Inactive tab |
| `tab-border` | Tab border |
| `title-bar-active` | Active title bar |
| `title-bar-inactive` | Inactive title bar |

**Usage:**
```nix
panelBg = semantic.ui "panel-background" mode;
hover = semantic.ui "element-hover" mode;
selected = semantic.ui "element-selected" mode;
```

---

### 📝 text - Text Hierarchy

Different levels of text importance.

| Name | Purpose |
|------|---------|
| `primary` | Primary text |
| `secondary` | Secondary/dimmed text |
| `tertiary` | Even more dimmed |
| `disabled` | Disabled state text |
| `placeholder` | Input placeholder |
| `link` | Hyperlink |
| `link-hover` | Hyperlink on hover |

**Usage:**
```nix
primary = semantic.text "primary" mode;
secondary = semantic.text "secondary" mode;
link = semantic.text "link" mode;
```

---

### 💻 terminal - ANSI Colors

Standard 16-color terminal palette.

| Normal | Bright |
|--------|--------|
| `ansi-black` | `ansi-bright-black` |
| `ansi-red` | `ansi-bright-red` |
| `ansi-green` | `ansi-bright-green` |
| `ansi-yellow` | `ansi-bright-yellow` |
| `ansi-blue` | `ansi-bright-blue` |
| `ansi-magenta` | `ansi-bright-magenta` |
| `ansi-cyan` | `ansi-bright-cyan` |
| `ansi-white` | `ansi-bright-white` |

**Usage:**
```nix
red = semantic.terminal "ansi-red" mode;
brightRed = semantic.terminal "ansi-bright-red" mode;
```

---

### ✏️ editor - Editor-Specific UI

Editor interface elements.

| Name | Purpose |
|------|---------|
| `background` | Editor background |
| `foreground` | Editor text |
| `gutter-background` | Line number gutter |
| `active-line-background` | Current line highlight |
| `line-number` | Line numbers |
| `active-line-number` | Current line number |
| `indent-guide` | Indentation guides |
| `indent-guide-active` | Active indent guide |
| `invisible` | Invisible characters |
| `bracket-match-background` | Matching bracket |
| `find-match-background` | Find/search matches |
| `find-match-foreground` | Find match text |
| `scrollbar-thumb` | Scrollbar handle |
| `scrollbar-track` | Scrollbar background |

**Usage:**
```nix
editorBg = semantic.editor "background" mode;
lineNumber = semantic.editor "line-number" mode;
activeLine = semantic.editor "active-line-background" mode;
```

---

### 🌈 syntax - Code Highlighting

Syntax highlighting for programming languages.

| Name | Examples |
|------|----------|
| `keyword` | `if`, `for`, `return`, `class` |
| `function` | Function names, method calls |
| `string` | `"hello"`, `'world'` |
| `number` | `42`, `3.14`, `0xFF` |
| `comment` | `// comment`, `/* block */` |
| `type` | `String`, `int`, type names |
| `variable` | Variable names |
| `constant` | `TRUE`, `NULL`, constants |
| `operator` | `+`, `-`, `*`, `/`, `&&` |
| `tag` | HTML/XML tags |
| `attribute` | HTML attributes |
| `preprocessing` | `#include`, preprocessor |
| `punctuation` | `()`, `[]`, `{}`, `;` |
| `escape` | `\n`, `\t`, escape sequences |

**Usage:**
```nix
keyword = semantic.syntax "keyword" mode;
string = semantic.syntax "string" mode;
comment = semantic.syntax "comment" mode;
```

---

### 📄 markup - Markdown/Documentation

Markup and documentation colors.

| Name | Purpose |
|------|---------|
| `heading` | Markdown headings |
| `bold` | **Bold text** |
| `italic` | *Italic text* |
| `link` | [Link text] |
| `link-url` | Link URL |
| `code` | Inline `code` |
| `code-block` | Code block background |
| `quote` | > Quote text |
| `list-marker` | - List bullets |

**Usage:**
```nix
heading = semantic.markup "heading" mode;
code = semantic.markup "code" mode;
```

---

### 🔄 vcs - Version Control Status

Git status indicators.

| Name | Git Status |
|------|------------|
| `added` | New files/lines (green) |
| `modified` | Changed files/lines (blue) |
| `deleted` | Deleted files/lines (red) |
| `renamed` | Renamed files |
| `conflict` | Merge conflicts (yellow) |
| `ignored` | Ignored files (gray) |

**Usage:**
```nix
added = semantic.vcs "added" mode;
modified = semantic.vcs "modified" mode;
deleted = semantic.vcs "deleted" mode;
```

---

### ⚠️ status - Indicators and States

Semantic status colors.

| Name | Purpose |
|------|---------|
| `error` | Errors (red) |
| `warning` | Warnings (yellow) |
| `success` | Success (green) |
| `info` | Information (blue) |
| `hint` | Subtle hints (gray) |

**Usage:**
```nix
error = semantic.status "error" mode;
warning = semantic.status "warning" mode;
success = semantic.status "success" mode;
```

---

### 👥 multiplayer - Collaboration Colors

Distinct per-user colors for collaborative editing.

| Name |
|------|
| `player-1` through `player-8` |

**Usage:**
```nix
user1 = semantic.multiplayer "player-1" mode;
user2 = semantic.multiplayer "player-2" mode;
```

---

## Advanced Usage

### Common Patterns

#### Terminal Configuration

```nix
colors = {
  background = semantic.core "background" mode;
  foreground = semantic.core "foreground" mode;
  cursor = semantic.core "cursor" mode;
};

ansi = {
  black = semantic.terminal "ansi-black" mode;
  red = semantic.terminal "ansi-red" mode;
  green = semantic.terminal "ansi-green" mode;
  yellow = semantic.terminal "ansi-yellow" mode;
  blue = semantic.terminal "ansi-blue" mode;
  magenta = semantic.terminal "ansi-magenta" mode;
  cyan = semantic.terminal "ansi-cyan" mode;
  white = semantic.terminal "ansi-white" mode;
};
```

#### Editor Configuration

```nix
editor = {
  background = semantic.editor "background" mode;
  foreground = semantic.editor "foreground" mode;
  lineNumber = semantic.editor "line-number" mode;
  activeLine = semantic.editor "active-line-background" mode;
};

syntax = {
  keyword = semantic.syntax "keyword" mode;
  function = semantic.syntax "function" mode;
  string = semantic.syntax "string" mode;
  comment = semantic.syntax "comment" mode;
};
```

#### UI Application

```nix
ui = {
  background = semantic.core "background" mode;
  foreground = semantic.core "foreground" mode;
  panelBg = semantic.ui "panel-background" mode;
  border = semantic.ui "panel-border" mode;
  hover = semantic.ui "element-hover" mode;
  selected = semantic.ui "element-selected" mode;
};

status = {
  error = semantic.status "error" mode;
  warning = semantic.status "warning" mode;
  success = semantic.status "success" mode;
};
```

### Bulk Operations

Get all colors for a category:

```nix
allCore = semantic.getAllColors "core" mode;
# Returns: { background = {...}; foreground = {...}; ... }

bg = allCore.background.hex;
fg = allCore.foreground.hex;
```

### Query Available Names

```nix
# Get all categories
categories = semantic.getAvailableCategories;
# ["core" "ui" "text" "terminal" "editor" "syntax" "markup" "vcs" "status" "multiplayer"]

# Get names in a category
coreNames = semantic.getAvailableNames "core";
# ["background" "foreground" "cursor" "selection-bg" "selection-fg" "focus"]
```

### Helper Functions (Edge Cases)

For rare cases not covered by semantic categories:

#### `getCategorical` - Raw Data-Viz Colors

Use when you need raw categorical colors (data-viz-01 through data-viz-08):

```nix
# Custom charting/visualization
colors = {
  chart1 = (semantic.getCategorical "data-viz-01" mode).hex;
  chart2 = (semantic.getCategorical "data-viz-02" mode).hex;
  chart3 = (semantic.getCategorical "data-viz-03" mode).hex;
};
```

**When to use:**
- Custom charting/visualization
- Multi-colored process lists (like procs)
- Distinct but non-semantic colors

#### `getAccent` - Tier-Specific Access

Use when you need a specific OKLCH tier (Lc75 or Lc60):

```nix
# GTK Adwaita requires Lc60 specifically
accentColor = (semantic.getAccent "primary" "Lc60").${mode}.hex;
```

**When to use:**
- Framework requires specific lightness/chroma tier
- Accessibility requirements mandate specific contrast tier
- Design system spec requires exact tier (like GTK Adwaita)

**Note:** Returns ALL modes, so you must specify `.${mode}` afterward.

#### `getTonal` - Extreme Contrast

Use for special tonal colors like pure black/white:

```nix
# Subtitle backgrounds need absolute black
subtitleBg = (semantic.getTonal "black" mode).hex;
pureWhite  = (semantic.getTonal "white" mode).hex;
```

**When to use:**
- Extreme contrast requirements (WCAG AAA)
- Opaque overlays
- Absolute extremes needed for visual clarity

---

## Rules & Validation

### Best Practices

#### ✅ DO

- Use semantic categories for all color access
- Name colors by **intention** not implementation
- Group related colors together
- Add comments explaining color choices
- Use helpers (`getCategorical`, etc.) for documented exceptions

#### ❌ DON'T

- Access `palette.*` or `signalPalette.*` directly
- Hardcode hex values (`"#1a1b1e"`)
- Use implementation names (`"surface-base"`) in module code
- Bypass semantic bridge without documentation
- Create local palette references (`inherit (signalPalette) accent;`)

### Exceptions

**Direct access is ONLY allowed when:**

1. **Documented architectural requirement** exists
2. **Comment explains** why semantic bridge doesn't work
3. **Uses helper functions** (`getCategorical`, `getAccent`, `getTonal`)

#### Example: GTK Module

```nix
# ✅ ALLOWED: Documented exception
# GTK/Adwaita requires specific Lc60 tier for accent colors
# This is a documented exception to semantic bridge usage
# See: https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/named-colors.html
accentPresets = {
  accent-green = (semantic.getAccent "primary" "Lc60").${themeMode}.hex;
  accent-red   = (semantic.getAccent "danger" "Lc60").${themeMode}.hex;
};
```

### Validation

Automated checks enforce semantic bridge usage:

```bash
# Run validation
nix build .#checks.x86_64-linux.semantic-bridge-enforcement

# Run all checks
nix flake check
```

**What's validated:**

```nix
# ❌ FORBIDDEN: Direct access
palette.tonal.dark."surface-base"
signalPalette.accent.primary.Lc75
palette.categorical.dark."data-viz-01"

# ✅ REQUIRED: Semantic bridge
semantic.core "background" mode
semantic.getCategorical "data-viz-01" mode
semantic.getAccent "primary" "Lc60"
semantic.getTonal "black" mode
```

### Error Messages

The semantic bridge provides helpful errors:

```nix
# Typo in semantic name
semantic.core "backgroud" mode
# ❌ Semantic name 'backgroud' not found in category 'core'
#
# Did you mean one of these?
#   - background
#   - foreground
#
# Available names in 'core':
#   - background
#   - foreground
#   - cursor
#   - selection-bg
#   ...

# Wrong category
semantic.syntax "background" mode
# ❌ Semantic name 'background' not found in category 'syntax'
#
# Available names in 'syntax':
#   - keyword
#   - function
#   - string
#   ...
#
# 💡 Tip: Check semantic.core or semantic.ui categories first.
```

---

## Migration Guide

### Migrating from Direct Palette Access

#### Direct Tonal Access

```nix
# ❌ Before
bg = palette.tonal.dark."surface-base".hex;

# ✅ After
bg = (semantic.core "background" mode).hex;
```

#### Direct Accent Access

```nix
# ❌ Before
primary = signalPalette.accent.primary.Lc75.dark.hex;

# ✅ After
primary = (semantic.status "success" mode).hex;

# Or if you need tier control:
primary = (semantic.getAccent "primary" "Lc75").${mode}.hex;
```

#### Direct Categorical Access

```nix
# ❌ Before
viz1 = palette.categorical.dark."data-viz-01".hex;

# ✅ After
viz1 = (semantic.getCategorical "data-viz-01" mode).hex;

# Or use multiplayer category if applicable:
viz1 = (semantic.multiplayer "player-1" mode).hex;
```

### Finding Violations

```bash
# Search for direct palette access
rg 'signalPalette\.(tonal|accent|categorical)' modules/
rg 'palette\.(tonal|accent|categorical)' modules/
```

### Common Patterns

| Old Pattern | New Pattern | Category |
|-------------|-------------|----------|
| `palette.tonal.*.surface-base` | `semantic.core "background"` | core |
| `palette.tonal.*.text-primary` | `semantic.core "foreground"` | core |
| `palette.accent.primary.Lc75` | `semantic.status "success"` | status |
| `palette.accent.danger.Lc75` | `semantic.status "error"` | status |
| `palette.accent.info.Lc75` | `semantic.text "link"` | text |
| `palette.categorical.*."data-viz-*"` | `semantic.getCategorical "data-viz-*"` | helper |

---

## Module Template

```nix
# modules/myapp/default.nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;  # Resolve once
in {
  colors = {
    # Primary interface - use these 99% of the time
    bg = (semantic.core "background" mode).hex;
    fg = (semantic.core "foreground" mode).hex;

    # Status colors
    error = (semantic.status "error" mode).hex;
    success = (semantic.status "success" mode).hex;

    # Syntax highlighting
    keyword = (semantic.syntax "keyword" mode).hex;
    string = (semantic.syntax "string" mode).hex;

    # Helpers - use for documented exceptions
    viz = (semantic.getCategorical "data-viz-01" mode).hex;
    tier = (semantic.getAccent "primary" "Lc60").${mode}.hex;
    extreme = (semantic.getTonal "black" mode).hex;
  };
}
```

---

## Resources

- **Integration Details:** [signal-palette-integration.md](./signal-palette-integration.md) - How colors are imported
- **Source Code:** `lib/semantic.nix` - Semantic bridge implementation
- **Upstream:** [signal-palette](https://github.com/lewisflude/signal-palette) - Color definitions
- **Examples:** [examples/](../examples/) - Real-world usage
- **Module Template:** [templates/module-template.nix](../templates/module-template.nix)

---

**Last Updated:** 2026-01-21
**Version:** 1.0.1
**Enforcement:** Automated via `tests/validation/semantic-bridge-enforcement.nix`
