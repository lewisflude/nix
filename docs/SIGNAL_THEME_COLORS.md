
Signal: Canonical Color Token List (Light & Dark Mode)
======================================================

This document provides the complete, canonical list of the 30 semantic color tokens that comprise the **Signal** color system.

Each token references two distinct, scientifically-derived Oklch values:

1. **Light Mode Value:** Calculated against a light base background (`oklch(0.95 0.01 240)`).

2. **Dark Mode Value:** Re-calculated against a dark base background (`oklch(0.15 0.01 240)`).

All color values are the Oklch "source of truth."

Method 1: Tonal Palette (10 Tokens)
-----------------------------------

**Functional Context:** Establishes the foundational visual hierarchy for text, surfaces, and borders. Each token is engineered to a precise APCA Lightness Contrast (Lc) score relative to its base background.

**Semantic Token**

**Role**

**Light Mode Value (Base: L095)**

**Dark Mode Value (Base: L015)**

`surface-base`

Primary UI background

`oklch(0.95 0.01 240)`

`oklch(0.15 0.01 240)`

`surface-subtle`

Card/Sidebar background

`oklch(0.92 0.01 240)` (Lc 5)

`oklch(0.20 0.01 240)` (Lc 5)

`surface-hover`

Subtle hover state

`oklch(0.88 0.01 240)` (Lc 10)

`oklch(0.25 0.01 240)` (Lc 10)

`divider-primary`

Standard border/divider

`oklch(0.84 0.01 240)` (Lc 15)

`oklch(0.30 0.01 240)` (Lc 15)

`divider-strong`

Input border, strong divider

`oklch(0.72 0.01 240)` (Lc 30)

`oklch(0.42 0.01 240)` (Lc 30)

`text-primary`

Primary body text

`oklch(0.42 0.01 240)` (Lc 75)

`oklch(0.85 0.01 240)` (Lc 75)

`text-secondary`

Sub-headings, captions

`oklch(0.51 0.01 240)` (Lc 60)

`oklch(0.67 0.01 240)` (Lc 60)

`text-tertiary`

Hint/placeholder text

`oklch(0.62 0.01 240)` (Lc 45)

`oklch(0.55 0.01 240)` (Lc 45)

`white`

Absolute white utility

`oklch(1 0 0)`

`oklch(1 0 0)`

`black`

Absolute black utility

`oklch(0 0 0)`

`oklch(0 0 0)`

Method 2: Accent Palette Sets (12 Tokens)
-----------------------------------------

**Functional Context:** Defines "Equi-Functional" accent palettes where all colors in a set (e.g., Lc 75) have equivalent functional legibility. All values are gamut-aware and independently re-calculated for both themes.

### Primary Accent Set (High-Priority: Lc 75)

**Semantic Token**

**Role**

**Light Mode Value (Lc 75)**

**Dark Mode Value (Lc 75)**

`accent-primary`

Primary CTA, Success

`oklch(0.71 0.2 130)` (h130)

`oklch(0.84 0.18 130)`

`accent-danger`

Error, Destructive

`oklch(0.64 0.23 40)` (h40)

`oklch(0.80 0.19 40)`

`accent-warning`

Warning, In-progress

`oklch(0.79 0.15 90)` (h90)

`oklch(0.92 0.15 90)`

`accent-info`

Informational, Links

`oklch(0.62 0.16 240)` (h240)

`oklch(0.82 0.1 240)`

`accent-secondary`

Secondary Accent

`oklch(0.74 0.12 190)` (h190)

`oklch(0.86 0.11 190)`

`accent-tertiary`

Tertiary Accent

`oklch(0.60 0.19 290)` (h290)

`oklch(0.79 0.16 290)`

### Secondary Accent Set (Medium-Priority: Lc 60)

**Semantic Token**

**Role**

**Light Mode Value (Lc 60)**

**Dark Mode Value (Lc 60)**

`accent-primary-subtle`

Success Tag

`oklch(0.76 0.18 130)` (h130)

`oklch(0.76 0.18 130)`

`accent-danger-subtle`

Warning Tag

`oklch(0.70 0.2 40)` (h40)

`oklch(0.70 0.2 40)`

`accent-warning-subtle`

In-progress Tag

`oklch(0.83 0.13 90)` (h90)

`oklch(0.83 0.13 90)`

`accent-info-subtle`

Info Tag

`oklch(0.68 0.14 240)` (h240)

`oklch(0.74 0.1 240)`

`accent-secondary-subtle`

Secondary Tag

`oklch(0.79 0.1 190)` (h190)

`oklch(0.79 0.1 190)`

`accent-tertiary-subtle`

Tertiary Tag

`oklch(0.66 0.17 290)` (h290)

`oklch(0.70 0.14 290)`

Method 3: Categorical Palette (8 Tokens)
----------------------------------------

**Functional Context:** A palette for data visualization where hues are generated using the Golden Angle iterator. The Dark Mode set is re-calculated for a consistent `Lc 45` against the dark background.

**Semantic Token**

**Role (Index)**

**Light Mode Value (L=0.75)**

**Dark Mode Value (Lc 45)**

`data-viz-01`

Chart Color 1

`oklch(0.75 0.15 40)`

`oklch(0.65 0.15 40)`

`data-viz-02`

Chart Color 2

`oklch(0.75 0.15 177.5)`

`oklch(0.68 0.15 177.5)`

`data-viz-03`

Chart Color 3

`oklch(0.75 0.15 315)`

`oklch(0.63 0.15 315)`

`data-viz-04`

Chart Color 4

`oklch(0.75 0.15 92.5)`

`oklch(0.70 0.15 92.5)`

`data-viz-05`

Chart Color 5

`oklch(0.75 0.15 230)`

`oklch(0.65 0.15 230)`

`data-viz-06`

Chart Color 6

`oklch(0.75 0.15 67.5)`

`oklch(0.68 0.15 67.5)`

`data-viz-07`

Chart Color 7

`oklch(0.75 0.15 205)`

`oklch(0.68 0.15 205)`

`data-viz-08`

Chart Color 8

`oklch(0.75 0.15 342.5)`

`oklch(0.64 0.15 342.5)`
