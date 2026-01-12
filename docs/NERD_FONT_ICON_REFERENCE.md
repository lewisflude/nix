# Nerd Font Icon Reference for Workspace Labels

Current icons that you don't like and better alternatives:

## Browser (Workspace 1-2)

**Current:** `󰈹` (Chrome icon)

**Better alternatives:**

- `` - Globe/web icon (clean, universal)
- `󰇧` - Chrome browser
- `󰊯` - Firefox browser
- `󰖟` - Earth/global icon
- `󰀏` - Safari browser

**Recommended:** `` or `󰖟`

## Development (Workspace 3-4)

**Current:** `󰨞` (VS Code icon - ironic since you use Helix/Zed)

**Better alternatives:**

- `` - Code brackets (universal, not tool-specific)
- `󰅩` - Terminal window
- `󰈮` - Code file
- `` - Text editor
- `󰅨` - Console/terminal
- `󰯂` - Zed icon (if you prefer)

**Recommended:** `` (most universal) or `󰅩` (terminal-focused)

## Communication (Workspace 5-6)

**Current:** `󰭹` (Chat bubble)

**Better alternatives:**

- `󰻞` - Speech bubble
- `󰍩` - Message/mail
- `󱋊` - Discord icon
- `󰇮` - Email
- `󰻌` - Comments/discussion

**Recommended:** `󰻞` or `󱋊` (if you use Discord)

## Media (Workspace 7-8)

**Current:** `󰝚` (Spotify icon)

**Better alternatives:**

- `󰎆` - Music note
- `󰈣` - Headphones
- `󰐌` - Play button
- `󰝚` - Spotify (current, actually good if you use it)
- `󰲸` - Music album
- `󱍙` - Obsidian icon (if that's your main use)

**Recommended:** `󰎆` (music note) or keep `󰝚` if you like it

## Gaming (Workspace 9)

**Current:** `󰊴` (Game controller)

**Better alternatives:**

- `󰖺` - Steam icon (perfect since you use Steam!)
- `󰺵` - Gamepad/controller
- `󰊗` - Joystick
- `󰊴` - Controller (current is fine)

**Recommended:** `󰖺` (Steam icon) since all your games are Steam

## Extra (Workspace 10)

**Current:** `󰋙` (Dots/more)

**Better alternatives:**

- `󰝖` - Three dots horizontal
- `󰇘` - Plus icon
- `󰐕` - Grid/apps
- `󱃔` - Asterisk
- `󰋙` - Ellipsis (current is fine)

**Recommended:** Keep `󰋙` or use `󰇘` (plus for "extra")

---

## Recommended Complete Set

```nix
name_map = {
  "1" = "";     # Browser primary (globe)
  "2" = "";     # Browser secondary (globe alt)
  "3" = "";     # Development primary (code brackets)
  "4" = "󰅩";     # Development secondary (terminal)
  "5" = "󰻞";     # Communication primary (chat)
  "6" = "󱋊";     # Communication secondary (Discord)
  "7" = "󰎆";     # Media primary (music note)
  "8" = "󱍙";     # Media secondary (Obsidian)
  "9" = "󰖺";     # Gaming (Steam icon!)
  "10" = "󰇘";    # Extra (plus)
};
```

## Alternative: Minimalist Numbers with Visual Distinction

```nix
name_map = {
  "1" = "󰲠";     # Circle 1
  "2" = "󰲢";     # Circle 2
  "3" = "󰲤";     # Circle 3
  "4" = "󰲦";     # Circle 4
  "5" = "󰲨";     # Circle 5
  "6" = "󰲪";     # Circle 6
  "7" = "󰲬";     # Circle 7
  "8" = "󰲮";     # Circle 8
  "9" = "󰲰";     # Circle 9
  "10" = "󰿪";    # Circle 10
};
```

## Alternative: Simple Geometric Shapes

```nix
name_map = {
  "1" = "●";     # Circle
  "2" = "■";     # Square
  "3" = "▲";     # Triangle up
  "4" = "◆";     # Diamond
  "5" = "★";     # Star
  "6" = "▼";     # Triangle down
  "7" = "◎";     # Bullseye
  "8" = "◢";     # Triangle right
  "9" = "◉";     # Double circle
  "10" = "⬡";    # Hexagon
};
```

---

## How to Find More Icons

### Method 1: Nerd Font Cheat Sheet (Best)

Visit: <https://www.nerdfonts.com/cheat-sheet>

Search for keywords like:

- "browser", "web", "chrome"
- "code", "terminal", "dev"
- "chat", "message", "discord"
- "music", "spotify", "media"
- "game", "steam", "controller"

### Method 2: Command Line

```bash
# List all Nerd Font glyphs (warning: huge output)
fc-list | grep -i nerd

# Or use a glyph picker
gucharmap  # GNOME Character Map
```

### Method 3: Test Icons Live

Just edit the `name_map` in your config and rebuild with `nh home switch` - instant preview!

---

## My Personal Recommendations

**For your use case (Chromium, Helix/Zed, Discord, Obsidian, Steam):**

```nix
name_map = {
  "1" = "";     # Web - universal, not browser-specific
  "2" = "󰖟";     # Web 2 - earth icon
  "3" = "";     # Dev - code brackets (not editor-specific)
  "4" = "󰅩";     # Dev 2 - terminal
  "5" = "󱋊";     # Chat - Discord (since you use it)
  "6" = "󰻞";     # Chat 2 - generic chat bubble
  "7" = "󱍙";     # Media - Obsidian (your main use?)
  "8" = "󰎆";     # Media 2 - music note
  "9" = "󰖺";     # Gaming - STEAM (perfect!)
  "10" = "󰇘";    # Extra - plus
};
```

This set:

- ✅ Uses universal symbols (not tool-specific like VS Code)
- ✅ Steam icon for gaming (immediately recognizable)
- ✅ Discord icon for chat (if you use it)
- ✅ Clean, professional look
- ✅ Easy to distinguish at a glance

---

## How to Apply

Edit `modules/shared/features/theming/applications/desktop/ironbar-home.nix`:

Find the `name_map` section and replace with your chosen icons, then:

```bash
nix fmt modules/shared/features/theming/applications/desktop/ironbar-home.nix
nh home switch
```

**Pick what feels right to YOU!** These are just suggestions. The best icons are the ones that make sense to your brain at a glance.
