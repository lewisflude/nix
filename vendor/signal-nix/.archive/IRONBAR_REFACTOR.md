## Ironbar CSS Refactoring Proposal

### Current Issue
The generated `style.css` includes layout, typography, and spacing - which are user preferences, not colors.

### Proposed Solution
Strip the CSS to **colors only** and provide a complete example CSS file that users can customize.

### Minimal Color-Only CSS

```nix
# modules/ironbar/default.nix
styleFile = pkgs.writeText "ironbar-signal-style.css" ''
  /**
   * IRONBAR SIGNAL THEME - COLORS ONLY
   * Generated from Signal Design System
   * 
   * This file ONLY contains color definitions.
   * For layout, spacing, and typography, see:
   * examples/ironbar-complete.css
   */

  /* =============================================================================
     SIGNAL COLOR TOKENS
     ============================================================================= */

  /* Text Colors */
  @define-color text_primary ${tokens.colors.text.primary};
  @define-color text_secondary ${tokens.colors.text.secondary};
  @define-color text_tertiary ${tokens.colors.text.tertiary};

  /* Surface Colors */
  @define-color surface_base ${tokens.colors.surface.base};
  @define-color surface_emphasis ${tokens.colors.surface.emphasis};

  /* Accent Colors */
  @define-color accent_focus ${tokens.colors.accent.focus};
  @define-color accent_success ${tokens.colors.accent.success};
  @define-color accent_warning ${tokens.colors.accent.warning};
  @define-color accent_danger ${tokens.colors.accent.danger};

  /* =============================================================================
     APPLY COLORS TO ELEMENTS
     Apply Signal colors while respecting your layout
     ============================================================================= */

  .background {
    background-color: transparent;
  }

  #bar {
    background-color: transparent;
  }

  /* Text */
  label {
    color: @text_primary;
  }

  /* Workspaces */
  .workspaces button {
    color: @text_tertiary;
    background-color: transparent;
  }

  .workspaces button.focused {
    color: @text_primary;
    border-left-color: @accent_focus;
  }

  .workspaces button:hover {
    color: @text_primary;
  }

  /* Window Title */
  .focused label {
    color: @text_secondary;
  }

  .focused.active {
    border-left-color: @accent_focus;
  }

  .focused.active label {
    color: @text_primary;
  }

  /* Control Buttons */
  button {
    background-color: transparent;
    color: @text_primary;
  }

  /* Battery States */
  .battery.warning {
    color: @accent_warning;
    border-left-color: @accent_warning;
  }

  .battery.critical {
    color: @accent_danger;
    border-left-color: @accent_danger;
  }

  /* Clock */
  .clock {
    color: @text_primary;
  }

  /* Power Button */
  .power {
    color: @accent_danger;
  }

  /* Layout Islands */
  #bar #start,
  #bar #center,
  #bar #end {
    background-color: @surface_base;
    border-color: @surface_emphasis;
  }
'';
```

### Complete Example CSS for Users

Create `examples/ironbar-complete.css`:

```css
/**
 * COMPLETE IRONBAR CONFIGURATION
 * This example shows how to combine Signal colors with your own layout preferences.
 * 
 * Usage:
 * 1. Enable Signal theme: theming.signal.ironbar.enable = true;
 * 2. Signal applies colors automatically
 * 3. Override styles in your own CSS file for layout/typography
 */

/* =============================================================================
   TYPOGRAPHY (User Preference)
   ============================================================================= */

* {
  font-family: "JetBrains Mono", monospace;  /* Your choice */
  font-size: 14px;                            /* Your choice */
}

/* =============================================================================
   LAYOUT (User Preference)
   ============================================================================= */

#bar {
  margin: 12px;  /* Your choice - adjust for your screen */
}

#bar #start,
#bar #center,
#bar #end {
  border-width: 2px;           /* Your choice */
  border-style: solid;         /* Your choice */
  border-radius: 16px;         /* Your choice */
  padding: 4px 16px;           /* Your choice */
}

#bar #start {
  margin-right: 16px;          /* Your choice */
}

#bar #center {
  margin: 0 8px;               /* Your choice */
}

#bar #end {
  margin-left: 16px;           /* Your choice */
}

/* =============================================================================
   WIDGET LAYOUT (User Preference)
   ============================================================================= */

.workspaces button {
  padding: 4px 8px;            /* Your choice */
  margin: 0 4px;               /* Your choice */
  border-radius: 12px;         /* Your choice */
}

.workspaces button.focused {
  border-left-width: 3px;      /* Your choice */
  border-left-style: solid;    /* Your choice */
}

.focused {
  padding: 4px 20px;           /* Your choice */
}

.focused.active {
  border-left-width: 3px;      /* Your choice */
  border-left-style: solid;    /* Your choice */
}

.tray .item {
  padding: 4px;                /* Your choice */
  margin: 0 3px;               /* Your choice */
  border-radius: 10px;         /* Your choice */
}

.clock {
  padding: 0 16px;             /* Your choice */
}

.notifications {
  padding: 0 8px;              /* Your choice */
}

/* =============================================================================
   COLORS
   Signal theme provides these automatically via @define-color tokens:
   - @text_primary, @text_secondary, @text_tertiary
   - @surface_base, @surface_emphasis
   - @accent_focus, @accent_warning, @accent_danger
   
   They're already applied to the right elements.
   You can override specific color choices here if needed.
   ============================================================================= */
```

### Migration Steps

1. **Update** `modules/ironbar/default.nix` to generate minimal color-only CSS
2. **Create** `examples/ironbar-complete.css` with layout examples
3. **Document** in README how users combine Signal colors + their layout
4. **Update** `modules/ironbar/config.nix` audit (separate task)

### Benefits

- ✅ Clear separation: Signal = colors, User = layout
- ✅ Users keep full control over spacing, fonts, sizing
- ✅ Signal stays focused on color consistency
- ✅ Example file shows best practices
- ✅ No breaking changes for users who don't override

### Documentation Addition

Add to README.md:

```markdown
### Ironbar

Signal provides color tokens for ironbar. You control the layout:

```nix
{
  # Signal provides colors
  theming.signal.ironbar.enable = true;
  
  # You control layout via your own CSS
  programs.ironbar.style = ./my-ironbar-layout.css;
}
```

See `examples/ironbar-complete.css` for a complete example combining Signal colors with custom layout.
```
