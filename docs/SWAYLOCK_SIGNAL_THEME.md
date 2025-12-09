# Swaylock-Effects Signal Theme Reference

Your swaylock-effects is themed with the **Signal OKLCH color palette** - a scientifically designed, perceptually uniform color system built for clarity and accessibility.

## Signal Theme Philosophy

**Signal: Perception, engineered.**

Signal is not just a color scheme - it's a framework for engineering clarity. Every color is the calculated solution to a functional problem, using:

- **OKLCH color space** for perceptual uniformity
- **APCA (Accessible Perceptual Contrast Algorithm)** for readability
- **Semantic naming** for predictable, intuitive UX

## Swaylock Color States

### Ring Colors (Primary Visual Feedback)

| State | Color | Hex | Meaning |
|-------|-------|-----|---------|
| **Default/Idle** | Focus Blue | `#5a7dcf` | Neutral, awaiting input |
| **Verifying** | Primary Green | `#4db368` | Success, authentication in progress |
| **Clearing** | Info Cyan | `#5aabb9` | Neutral action, clearing input |
| **Wrong Password** | Danger Red | `#d9574a` | Error, authentication failed |

### Inside Colors (Indicator Background)

| State | Base Color | Hex | Alpha | Visual |
|-------|-----------|-----|-------|--------|
| **Default** | Surface Base | `#1e1f26` | `dd` (87%) | Solid, grounded |
| **Verifying** | Surface Subtle | `#25262f` | `dd` (87%) | Slightly elevated |
| **Clearing** | Surface Base | `#1e1f26` | `bb` (73%) | More transparent |
| **Wrong** | Surface Emphasis | `#2d2e39` | `dd` (87%) | Emphasized warning |

### Text Colors

| Element | Color | Hex | Purpose |
|---------|-------|-----|---------|
| **Clock/Date** | Text Primary | `#c0c3d1` | High contrast, always readable |
| **Verifying Text** | Primary Green | `#4db368` | Positive feedback |
| **Clear Text** | Info Cyan | `#5aabb9` | Neutral feedback |
| **Error Text** | Danger Red | `#d9574a` | Error state |

### Keyboard Feedback

| Action | Color | Hex |
|--------|-------|-----|
| **Key Press** | Info Cyan | `#5aabb9` |
| **Backspace** | Danger Red | `#d9574a` |

## Visual Effects

Your configuration uses these swaylock-effects exclusive features:

### Background Processing

- **Screenshots**: Captures your desktop before locking
- **Blur**: 7x5 Gaussian blur for privacy and aesthetics
- **Vignette**: 0.5:0.5 subtle darkening at edges for depth

### Transitions

- **Fade-in**: 200ms smooth transition when lock activates
- **Grace Period**: 2 seconds before password is required

### Indicator

- **Radius**: 110px circular indicator
- **Thickness**: 7px ring
- **Clock**: Time (12-hour) and date display
- **Failed Attempts**: Shows authentication failure count

## Customization Options

### More Blur for Privacy

If you want stronger blur (more privacy, less recognizable):

```nix
effect-blur = "10x7";  # Heavier blur
```

### Different Vignette

Adjust the vignette effect (base:factor, range 0-1):

```nix
effect-vignette = "0.3:0.7";  # Darker edges
effect-vignette = "0.7:0.3";  # Lighter edges
```

### Longer Grace Period

Useful if you frequently unlock quickly:

```nix
grace = 5;  # 5 seconds before requiring password
grace-no-mouse = true;  # Require keyboard during grace period
```

### Image Overlay

Add a logo or image to the lock screen:

```nix
effect-compose = "50%,50%;200x200;center;/path/to/logo.png";
```

Format: `position;size;gravity;path`

### Custom Text

Change the displayed text:

```nix
text-ver = "Authenticating...";
text-wrong = "Access Denied";
text-clear = "Cleared";
text-caps-lock = "CAPS LOCK";
```

### Pixelate Instead of Blur

For a different aesthetic:

```nix
# effect-blur = "7x5";  # Comment out blur
effect-pixelate = 10;  # Pixelate with 10x10 blocks
```

### Greyscale Effect

Make the background black and white:

```nix
effect-greyscale = true;
```

## Signal Palette Reference (Dark Mode)

### Tonal Colors (Neutrals)

| Name | Hex | L | C | H | Usage |
|------|-----|---|---|---|-------|
| `base-L000` | `#000000` | 0.00 | 0.00 | 0 | Pure black |
| `base-L015` | `#1e1f26` | 0.15 | 0.01 | 240 | Base background |
| `surface-Lc05` | `#25262f` | 0.19 | 0.01 | 240 | Surface |
| `surface-Lc10` | `#2d2e39` | 0.23 | 0.02 | 240 | Elevated surface |
| `divider-Lc15` | `#353642` | 0.27 | 0.02 | 240 | Subtle divider |
| `divider-Lc30` | `#454759` | 0.35 | 0.03 | 240 | Visible divider |
| `text-Lc45` | `#6b6f82` | 0.50 | 0.04 | 240 | Tertiary text |
| `text-Lc60` | `#9498ab` | 0.65 | 0.05 | 240 | Secondary text |
| `text-Lc75` | `#c0c3d1` | 0.80 | 0.05 | 240 | Primary text |

### Accent Colors (Semantics)

| Name | Hex | L | C | H | Semantic Meaning |
|------|-----|---|---|---|------------------|
| `Lc75-h130` | `#4db368` | 0.71 | 0.20 | 130 | **Primary/Success** (Green) |
| `Lc75-h040` | `#d9574a` | 0.64 | 0.23 | 40 | **Danger/Error** (Red) |
| `Lc75-h090` | `#c9a93a` | 0.79 | 0.15 | 90 | **Warning** (Yellow-Orange) |
| `Lc75-h190` | `#5aabb9` | 0.73 | 0.12 | 190 | **Info** (Cyan) |
| `Lc75-h240` | `#5a7dcf` | 0.68 | 0.18 | 240 | **Focus** (Blue) |
| `Lc75-h290` | `#a368cf` | 0.68 | 0.16 | 290 | **Special** (Purple) |

## Testing Your Lock Screen

To preview your lock screen:

```bash
# Lock immediately (bypasses grace period with -f flag)
swaylock -f

# Or use your shell alias
lock
```

## Technical Notes

### Why OKLCH?

Traditional RGB/HSL color spaces are not perceptually uniform - a change in lightness value doesn't produce the same perceived brightness change across different hues. OKLCH (Oklch) solves this:

- **L** (Lightness): 0.0 (black) to 1.0 (white), perceptually uniform
- **C** (Chroma): 0.0 (grayscale) to 0.4+ (vivid), represents colorfulness
- **H** (Hue): 0-360 degrees, traditional color wheel

This means:

- All colors at L=0.75 appear equally bright
- Consistent contrast across different hues
- Predictable color behavior when adjusting parameters

### Why These Specific Colors?

The Signal palette is mathematically optimized for:

1. **Accessibility**: APCA contrast ratios ensure readability
2. **Semantic Clarity**: Colors map to universal meanings (green=success, red=danger)
3. **Perceptual Uniformity**: Equal visual weight across all accent colors
4. **Professional Aesthetics**: Subtle chroma values prevent visual fatigue

## Related Documentation

- **Signal Theme Overview**: `modules/shared/features/theming/palette.nix`
- **Theme Library**: `modules/shared/features/theming/lib.nix`
- **Swaylock PAM Configuration**: `modules/nixos/core/security.nix`
- **Swayidle Integration**: `home/nixos/apps/swayidle.nix`

## Troubleshooting

### Lock screen doesn't appear

Check that swaylock has permissions:

```bash
# Check PAM configuration
cat /etc/pam.d/swaylock

# Ensure seat file is readable
ls -la /run/systemd/seats/
```

### Colors look different

Monitor color profiles affect appearance. Signal colors are optimized for sRGB displays. If using a wide-gamut monitor, your desktop environment may need color management configuration.

### Effects not working

Ensure you're using `swaylock-effects`, not vanilla `swaylock`:

```bash
swaylock --version
# Should show: swaylock version 1.7.x.x or similar with effects support
```
