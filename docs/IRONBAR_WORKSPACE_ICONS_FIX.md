# Ironbar Workspace Icons Not Showing

## Problem

You're seeing **application icons** (Firefox, globe, VS Code) instead of the semantic workspace icons we configured (󰈹, 󰨞, etc.).

This happens because ironbar's `workspaces` widget prioritizes showing the focused window's application icon over the `name_map` text.

## Quick Fix Applied

Added to workspace configuration:

```nix
show_icon = false;  # Disable application icons, use name_map instead
icon_size = 18;     # Size for semantic icons
```

**Test:** Rebuild with `nh home switch` and check if semantic icons appear.

## If Icons Still Don't Show

Ironbar's `workspaces` widget might not support `name_map` with Nerd Font icons. Here are alternatives:

### Solution 1: Text Labels (Simplest, Always Works)

Replace semantic icons with short text:

```nix
name_map = {
  "1" = "Web";
  "3" = "Dev";
  "5" = "Chat";
  "7" = "Media";
  "9" = "Game";
};
```

**Pros:** Reliable, readable
**Cons:** Takes more space, less visual

### Solution 2: CSS Pseudo-Elements (Best Balance)

Keep workspace numbers, add icons via CSS:

**In ironbar config:**

```nix
{
  type = "workspaces";
  # No name_map needed
  show_icon = false;
}
```

**In style.css:**

```css
/* Add icons before workspace buttons */
.workspaces button:nth-child(1)::before { content: "󰈹"; }
.workspaces button:nth-child(2)::before { content: "󰖟"; }
.workspaces button:nth-child(3)::before { content: "󰨞"; }
/* ... etc for all 10 ... */

/* Optional: Hide numbers, show only icons */
.workspaces button { font-size: 0; }
.workspaces button::before { font-size: 18px; }
```

**Pros:** Clean, reliable, separates style from config
**Cons:** Requires CSS editing

### Solution 3: Custom Script Widget (Most Power)

Parse niri's workspace state directly:

```nix
{
  type = "script";
  mode = "watch";
  cmd = ''
    niri msg --json event-stream | jq -r --unbuffered '
      select(.WorkspacesChanged != null) |
      # Parse workspaces, map to icons
      # See home/nixos/ironbar-workspace-alternatives.nix for full example
    '
  '';
}
```

**Pros:** Total control, dynamic
**Cons:** More complex, harder to debug

## Recommended Approach

1. **First:** Test current config with `show_icon = false` ✅ (applied)
2. **If that fails:** Use Solution 2 (CSS pseudo-elements)
3. **If you want text:** Use Solution 1 (text labels)

## Why Application Icons Appear

Ironbar's default behavior:

1. Check if workspace has focused window → Show window icon
2. Check if `name_map` exists → Show mapped text
3. Otherwise → Show workspace number

Our `name_map` has icons (󰈹) but ironbar sees windows and shows their icons instead (Firefox icon).

The `show_icon = false` flag should disable step 1, forcing step 2.

## Testing Checklist

After `nh home switch`:

- [ ] Do you see semantic icons (󰈹 󰨞 󰭹) or application icons (Firefox, VS Code)?
- [ ] Do icons change when you open/close applications?
- [ ] Are all 10 workspaces visible?

**Report back what you see!**

## If show_icon = false Works

Great! The bar will show:

- 󰈹 (Browser workspace - regardless of whether Chromium or Firefox is open)
- 󰨞 (Dev workspace - regardless of Helix/Zed/VS Code)
- 󰭹 (Chat workspace - consistent icon)

This is actually **better UX** because the workspace identity doesn't change based on what's running.

## If show_icon = false Doesn't Work

We'll implement Solution 2 (CSS pseudo-elements) which is the most reliable approach for Nerd Font icons.

---

**Bottom Line:** The `show_icon = false` fix should work. If not, CSS pseudo-elements are the bulletproof solution.
