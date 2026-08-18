# Signal Theme - Application Documentation Sources

This document provides authoritative documentation references for theming each application in the signal-nix project. It serves as the single source of truth for implementing Signal color themes across all supported applications.

## Purpose

For each application, this document provides:
- Official documentation links for color/theme configuration
- Configuration file format and syntax
- Nix integration method (home-manager options vs raw config)
- Color property schemas and naming conventions
- Special considerations and notes

---

## Terminal Emulators

### Alacritty

- **Official Website**: https://alacritty.org/
- **Config Documentation**: https://alacritty.org/config-alacritty.html
- **GitHub**: https://github.com/alacritty/alacritty
- **Config Format**: TOML (via Nix attrs)
- **Nix Integration**: `programs.alacritty.settings`
- **Color Schema**:
  ```toml
  [colors.primary]
  background = "#hex"
  foreground = "#hex"
  
  [colors.cursor]
  text = "#hex"
  cursor = "#hex"
  
  [colors.vi_mode_cursor]
  text = "#hex"
  cursor = "#hex"
  
  [colors.search.matches]
  foreground = "#hex"
  background = "#hex"
  
  [colors.search.focused_match]
  foreground = "#hex"
  background = "#hex"
  
  [colors.hints.start]
  foreground = "#hex"
  background = "#hex"
  
  [colors.hints.end]
  foreground = "#hex"
  background = "#hex"
  
  [colors.line_indicator]
  foreground = "None"
  background = "None"
  
  [colors.footer_bar]
  foreground = "#hex"
  background = "#hex"
  
  [colors.selection]
  text = "#hex"
  background = "#hex"
  
  [colors.normal]
  black = "#hex"
  red = "#hex"
  green = "#hex"
  yellow = "#hex"
  blue = "#hex"
  magenta = "#hex"
  cyan = "#hex"
  white = "#hex"
  
  [colors.bright]
  black = "#hex"
  red = "#hex"
  green = "#hex"
  yellow = "#hex"
  blue = "#hex"
  magenta = "#hex"
  cyan = "#hex"
  white = "#hex"
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.alacritty.enable
- **Notes**: Supports 16 ANSI colors, cursor colors, selection, search highlights, and hints. Auto-dimming available.

---

### Kitty

- **Official Website**: https://sw.kovidgoyal.net/kitty/
- **Config Documentation**: https://sw.kovidgoyal.net/kitty/conf/
- **Color Documentation**: https://sw.kovidgoyal.net/kitty/conf/#color-scheme
- **GitHub**: https://github.com/kovidgoyal/kitty
- **Config Format**: Custom kitty.conf syntax (via Nix attrs)
- **Nix Integration**: `programs.kitty.settings`
- **Color Schema**:
  ```conf
  # Basic colors
  foreground #hex
  background #hex
  
  # Cursor colors
  cursor #hex
  cursor_text_color #hex
  
  # Selection
  selection_foreground #hex
  selection_background #hex
  
  # URL color
  url_color #hex
  
  # Tab bar
  active_tab_foreground #hex
  active_tab_background #hex
  inactive_tab_foreground #hex
  inactive_tab_background #hex
  
  # Marks (highlights)
  mark1_foreground #hex
  mark1_background #hex
  mark2_foreground #hex
  mark2_background #hex
  mark3_foreground #hex
  mark3_background #hex
  
  # 16 ANSI colors
  color0  #hex  # black
  color1  #hex  # red
  color2  #hex  # green
  color3  #hex  # yellow
  color4  #hex  # blue
  color5  #hex  # magenta
  color6  #hex  # cyan
  color7  #hex  # white
  color8  #hex  # bright black
  color9  #hex  # bright red
  color10 #hex  # bright green
  color11 #hex  # bright yellow
  color12 #hex  # bright blue
  color13 #hex  # bright magenta
  color14 #hex  # bright cyan
  color15 #hex  # bright white
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.kitty.enable
- **Notes**: Very comprehensive theming. Supports tab bar, marks, and extensive color customization.

---

### WezTerm

- **Official Website**: https://wezfurlong.org/wezterm/
- **Config Documentation**: https://wezfurlong.org/wezterm/config/files.html
- **Color Documentation**: https://wezfurlong.org/wezterm/config/appearance.html
- **GitHub**: https://github.com/wez/wezterm
- **Config Format**: Lua
- **Nix Integration**: `programs.wezterm` (home-manager) or `xdg.configFile."wezterm/wezterm.lua".text`
- **Color Schema**:
  ```lua
  config.colors = {
    foreground = "#hex",
    background = "#hex",
    cursor_bg = "#hex",
    cursor_fg = "#hex",
    cursor_border = "#hex",
    selection_fg = "#hex",
    selection_bg = "#hex",
    
    -- ANSI colors
    ansi = {
      "#hex", -- black
      "#hex", -- red
      "#hex", -- green
      "#hex", -- yellow
      "#hex", -- blue
      "#hex", -- magenta
      "#hex", -- cyan
      "#hex", -- white
    },
    brights = {
      "#hex", -- bright black
      "#hex", -- bright red
      "#hex", -- bright green
      "#hex", -- bright yellow
      "#hex", -- bright blue
      "#hex", -- bright magenta
      "#hex", -- bright cyan
      "#hex", -- bright white
    },
    
    -- Tab bar
    tab_bar = {
      background = "#hex",
      active_tab = {
        bg_color = "#hex",
        fg_color = "#hex",
      },
      inactive_tab = {
        bg_color = "#hex",
        fg_color = "#hex",
      },
    },
  }
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.wezterm.enable
- **Notes**: Lua-based configuration. Very flexible and programmable.

---

### Ghostty

- **Official Website**: https://ghostty.org/
- **Config Documentation**: https://ghostty.org/docs/config/reference
- **GitHub**: https://github.com/ghostty-org/ghostty
- **Config Format**: Custom key=value format (via Nix attrs)
- **Nix Integration**: `programs.ghostty.settings`
- **Color Schema**:
  ```nix
  programs.ghostty.settings = {
    # Basic colors (hex WITHOUT # prefix)
    background = "rrggbb";
    foreground = "rrggbb";
    
    # Cursor colors
    "cursor-color" = "rrggbb";
    "cursor-text" = "rrggbb";
    
    # Selection colors
    "selection-background" = "rrggbb";
    "selection-foreground" = "rrggbb";
    
    # Split divider
    "split-divider-color" = "rrggbb";
    
    # ANSI colors via palette array
    palette = [
      "0=#rrggbb"
      "1=#rrggbb"
      "2=#rrggbb"
      "3=#rrggbb"
      "4=#rrggbb"
      "5=#rrggbb"
      "6=#rrggbb"
      "7=#rrggbb"
      "8=#rrggbb"   # bright black
      "9=#rrggbb"   # bright red
      "10=#rrggbb"  # bright green
      "11=#rrggbb"  # bright yellow
      "12=#rrggbb"  # bright blue
      "13=#rrggbb"  # bright magenta
      "14=#rrggbb"  # bright cyan
      "15=#rrggbb"  # bright white
    ];
  };
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ghostty.enable
- **Notes**: Key names with hyphens need quotes in Nix. Hex colors WITHOUT # for basic colors, WITH # for palette array. Very modern terminal.

---

## CLI Tools

### Bat (Syntax Highlighter)

- **Official Website**: https://github.com/sharkdp/bat
- **Theme Documentation**: https://github.com/sharkdp/bat#adding-new-themes
- **Sublime Text Theme Format**: https://www.sublimetext.com/docs/color_schemes.html
- **Config Format**: Sublime Text tmTheme (XML plist)
- **Nix Integration**: `programs.bat.themes` and `programs.bat.config`
- **Color Schema**: tmTheme XML format (see bat.nix for full example)
  ```xml
  <dict>
    <key>settings</key>
    <dict>
      <key>background</key>
      <string>#hex</string>
      <key>foreground</key>
      <string>#hex</string>
      <key>caret</key>
      <string>#hex</string>
      <key>lineHighlight</key>
      <string>#hex</string>
      <key>selection</key>
      <string>#hex</string>
    </dict>
  </dict>
  ```
  Plus scope-based syntax highlighting rules.
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.bat.enable
- **Notes**: Uses Sublime Text tmTheme format. Requires defining syntax scopes (comment, string, keyword, etc.).

---

### Delta (Git Diff Tool)

- **Official Website**: https://github.com/dandavison/delta
- **Config Documentation**: https://dandavison.github.io/delta/configuration.html
- **Features Documentation**: https://dandavison.github.io/delta/features-named-colors.html
- **Config Format**: gitconfig-style (via Nix attrs)
- **Nix Integration**: `programs.delta.options`
- **Color Schema**:
  ```ini
  # Syntax theme (uses bat themes)
  syntax-theme = "theme-name"
  
  # Line styles (can use hex or named terminal colors)
  minus-style = "syntax #background-hex"
  minus-emph-style = "syntax #background-hex"
  minus-non-emph-style = "syntax #background-hex"
  plus-style = "syntax #background-hex"
  plus-emph-style = "syntax #background-hex"
  plus-non-emph-style = "syntax #background-hex"
  
  # Line numbers
  line-numbers-minus-style = "#hex"
  line-numbers-plus-style = "#hex"
  line-numbers-zero-style = "#hex"
  line-numbers-left-style = "#hex"
  line-numbers-right-style = "#hex"
  
  # File decoration
  file-style = "#hex"
  file-decoration-style = "#hex ul"
  
  # Commit decoration
  commit-style = "#hex"
  commit-decoration-style = "#hex box"
  
  # Hunk header
  hunk-header-style = "syntax #hex"
  hunk-header-decoration-style = "#hex box"
  hunk-header-file-style = "#hex"
  hunk-header-line-number-style = "#hex"
  
  # Blame
  blame-palette = "#hex #hex #hex ..."
  
  # Merge conflict
  merge-conflict-ours-diff-header-style = "#hex bold"
  merge-conflict-theirs-diff-header-style = "#hex bold"
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.delta.enable
- **Notes**: Depends on bat for syntax highlighting. Supports style modifiers (bold, ul, box, etc.).

---

### Eza (Modern ls)

- **Official Website**: https://github.com/eza-community/eza
- **Documentation**: https://eza.rocks/
- **Color Documentation**: https://github.com/eza-community/eza/blob/main/man/eza_colors.5.md
- **Config Format**: Environment variables (`EZA_COLORS`)
- **Nix Integration**: `home.sessionVariables.EZA_COLORS`
- **Color Schema**: Colon-separated key=value pairs with ANSI codes or 256-color codes
  ```bash
  # Format: key1=value1:key2=value2:...
  EZA_COLORS="di=1;34:ex=1;32:fi=0:ln=1;36:..."
  
  # Common keys:
  # File types
  di=1;34          # directories - bold blue
  ex=1;32          # executables - bold green
  fi=0             # regular files
  ln=1;36          # symlinks
  or=31;40         # orphaned symlinks
  
  # Permissions
  ur=38;5;75       # user read (256-color)
  uw=38;5;203      # user write
  ux=38;5;120      # user execute
  gr=...           # group permissions
  tr=...           # other permissions
  
  # Git status
  ga=38;5;120      # added
  gm=38;5;111      # modified
  gd=38;5;203      # deleted
  gv=38;5;141      # renamed
  gt=38;5;180      # type changed
  gi=2;38;5;60     # ignored (dimmed)
  gc=1;38;5;203    # conflicted (bold)
  
  # Git repo
  Gm=1;38;5;111    # main branch
  Go=38;5;141      # other branch
  Gc=38;5;120      # clean
  Gd=38;5;203      # dirty
  
  # File types by category
  im=38;5;141      # images
  vi=38;5;120      # videos
  mu=38;5;111      # music
  do=38;5;75       # documents
  co=38;5;139      # compressed
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.eza.enable
- **Notes**: 
  - Uses ANSI color codes (0-7 normal, 30-37 fg, 40-47 bg, 1=bold, 2=dim, etc.)
  - 256-color format: `38;5;N` for foreground, `48;5;N` for background
  - Very extensive: file types, permissions, git status, user/group
  - Must be single string with colon separators

---

### FZF (Fuzzy Finder)

- **Official Website**: https://github.com/junegunn/fzf
- **Documentation**: https://github.com/junegunn/fzf
- **Color Documentation**: https://github.com/junegunn/fzf/wiki/Color-schemes
- **Config Format**: Command-line flags / environment variables
- **Nix Integration**: `programs.fzf.colors`
- **Color Schema**:
  ```bash
  --color=fg:#hex,bg:#hex,hl:#hex \
  --color=fg+:#hex,bg+:#hex,hl+:#hex \
  --color=info:#hex,prompt:#hex,pointer:#hex \
  --color=marker:#hex,spinner:#hex,header:#hex
  ```
  Elements: fg, bg, hl (highlight), fg+/bg+/hl+ (selected), info, prompt, pointer, marker, spinner, header, border, label, query
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fzf.enable
- **Notes**: Uses `--color` flag with key:value pairs. Can use hex colors or ANSI color names.

---

### Lazygit

- **Official Website**: https://github.com/jesseduffield/lazygit
- **Config Documentation**: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
- **Theme Documentation**: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md#color-attributes
- **Config Format**: YAML
- **Nix Integration**: `xdg.configFile."lazygit/config.yml"` or `programs.lazygit` (if available)
- **Color Schema**:
  ```yaml
  gui:
    theme:
      activeBorderColor:
        - "#hex"
        - bold
      inactiveBorderColor:
        - "#hex"
      optionsTextColor:
        - "#hex"
      selectedLineBgColor:
        - "#hex"
      selectedRangeBgColor:
        - "#hex"
      cherryPickedCommitBgColor:
        - "#hex"
      cherryPickedCommitFgColor:
        - "#hex"
      unstagedChangesColor:
        - "#hex"
      defaultFgColor:
        - "#hex"
  ```
- **Home Manager Options**: Check `search.nixos.org`
- **Notes**: YAML configuration. Supports style attributes (bold, underline, reverse).

---

### Yazi (File Manager)

- **Official Website**: https://github.com/sxyazi/yazi
- **Documentation**: https://yazi-rs.github.io/docs/configuration/theme
- **Theme Documentation**: https://yazi-rs.github.io/docs/configuration/theme
- **Config Format**: TOML
- **Nix Integration**: `programs.yazi` or `xdg.configFile."yazi/theme.toml"`
- **Color Schema**:
  ```toml
  [manager]
  cwd = { fg = "#hex" }
  hovered = { bg = "#hex", fg = "#hex" }
  preview_hovered = { bg = "#hex" }
  
  [status]
  separator_open = { fg = "#hex", bg = "#hex" }
  separator_close = { fg = "#hex", bg = "#hex" }
  
  [select]
  border = { fg = "#hex" }
  active = { fg = "#hex", bold = true }
  inactive = { fg = "#hex" }
  
  [input]
  border = { fg = "#hex" }
  title = { fg = "#hex" }
  value = { fg = "#hex" }
  selected = { bg = "#hex" }
  
  [completion]
  border = { fg = "#hex" }
  active = { bg = "#hex" }
  inactive = {}
  
  [tasks]
  border = { fg = "#hex" }
  title = { fg = "#hex" }
  hovered = { bg = "#hex" }
  
  [which]
  cols = 3
  mask = { bg = "#hex" }
  cand = { fg = "#hex" }
  rest = { fg = "#hex" }
  desc = { fg = "#hex" }
  separator = { fg = "#hex" }
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.yazi.enable
- **Notes**: Modern file manager with comprehensive theming. TOML-based theme files.

---

## Editors

### Helix

- **Official Website**: https://helix-editor.com/
- **Documentation**: https://docs.helix-editor.com/
- **Theme Documentation**: https://docs.helix-editor.com/themes.html
- **GitHub**: https://github.com/helix-editor/helix
- **Config Format**: TOML
- **Nix Integration**: `programs.helix.themes` and `programs.helix.settings`
- **Color Schema**: Theme definition with palette
  ```toml
  # Syntax scopes (referencing palette)
  "attribute" = "type"
  "type" = "type"
  "string" = "string"
  "comment" = { fg = "comment", modifiers = ["italic"] }
  
  # UI elements
  "ui.background" = { fg = "text", bg = "background" }
  "ui.cursor" = { fg = "background", bg = "cursor" }
  "ui.selection" = { bg = "selection" }
  
  # Palette (actual colors)
  [palette]
  background = "#hex"
  foreground = "#hex"
  string = "#hex"
  comment = "#hex"
  # ... etc
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.helix.enable
- **Notes**: Two-level theming: scopes reference palette colors. Very comprehensive UI theming.

---

### Neovim

- **Official Website**: https://neovim.io/
- **Documentation**: https://neovim.io/doc/
- **Highlight Documentation**: `:help highlight` or https://neovim.io/doc/user/syntax.html
- **Config Format**: Lua or Vimscript
- **Nix Integration**: `programs.neovim.extraLuaConfig` or colorscheme plugin
- **Color Schema**: Via highlight groups
  ```lua
  vim.api.nvim_set_hl(0, "Normal", { fg = "#hex", bg = "#hex" })
  vim.api.nvim_set_hl(0, "Comment", { fg = "#hex", italic = true })
  vim.api.nvim_set_hl(0, "String", { fg = "#hex" })
  vim.api.nvim_set_hl(0, "Keyword", { fg = "#hex" })
  -- ... many more highlight groups
  ```
  Or via Vimscript:
  ```vim
  hi Normal guifg=#hex guibg=#hex
  hi Comment guifg=#hex gui=italic
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.neovim.enable
- **Notes**: Requires defining many highlight groups. Can create Lua colorscheme or use Vimscript.

---

## Multiplexers

### Tmux

- **Official Website**: https://github.com/tmux/tmux
- **Documentation**: https://github.com/tmux/tmux/wiki
- **Manual**: `man tmux` or https://man.openbsd.org/tmux.1
- **Config Format**: Tmux commands
- **Nix Integration**: `programs.tmux.extraConfig`
- **Color Schema**:
  ```tmux
  # Status bar
  set-option -g status-style "bg=#hex,fg=#hex"
  
  # Status left/right
  set-option -g status-left "#[bg=#hex,fg=#hex,bold] #S "
  set-option -g status-right "#[fg=#hex]%Y-%m-%d #[fg=#hex]%H:%M"
  
  # Windows
  set-option -g window-status-style "bg=#hex,fg=#hex"
  set-option -g window-status-current-style "bg=#hex,fg=#hex,bold"
  set-option -g window-status-activity-style "bg=#hex,fg=#hex"
  set-option -g window-status-bell-style "bg=#hex,fg=#hex,bold"
  
  # Pane borders
  set-option -g pane-border-style "fg=#hex"
  set-option -g pane-active-border-style "fg=#hex"
  
  # Messages
  set-option -g message-style "bg=#hex,fg=#hex,bold"
  set-option -g message-command-style "bg=#hex,fg=#hex"
  
  # Mode (copy mode, etc.)
  set-option -g mode-style "bg=#hex,fg=#hex,bold"
  
  # Clock
  set-option -g clock-mode-colour "#hex"
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.tmux.enable
- **Notes**: Uses tmux `set-option` commands. Styles support modifiers (bold, dim, etc.).

---

### Zellij

- **Official Website**: https://zellij.dev/
- **Documentation**: https://zellij.dev/documentation/
- **Theme Documentation**: https://zellij.dev/documentation/themes
- **Config Format**: KDL (custom DSL) or Nix attrs
- **Nix Integration**: `programs.zellij.settings.themes`
- **Color Schema**: Complex component-based theming with RGB space-separated values
  ```nix
  programs.zellij.settings = {
    themes.signal = {
      # Text components (selected/unselected)
      text_unselected = {
        base = "R G B";  # Space-separated RGB values
        background = "R G B";
        emphasis_0 = "R G B";
        emphasis_1 = "R G B";
        emphasis_2 = "R G B";
        emphasis_3 = "R G B";
      };
      
      text_selected = { ... };  # Same structure
      
      # Ribbon components (tabs, status bar)
      ribbon_unselected = { ... };
      ribbon_selected = { ... };
      
      # Table components
      table_title = { ... };
      table_cell_unselected = { ... };
      table_cell_selected = { ... };
      
      # List components
      list_unselected = { ... };
      list_selected = { ... };
      
      # Frame (pane borders)
      frame_unselected = { ... };
      frame_selected = { ... };
      frame_highlight = { ... };
      
      # Exit code colors
      exit_code_success = { ... };
      exit_code_error = { ... };
      
      # Multiplayer user colors (array)
      multiplayer_user_colors = [
        "R G B"
        "R G B"
        # ... up to 10 colors
      ];
    };
    theme = "signal";
  };
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zellij.enable
- **Notes**: Uses RGB space-separated format (NOT hex). Very comprehensive component-based theming system. Each component has base, background, and 4 emphasis colors.

---

## Prompts

### Starship

- **Official Website**: https://starship.rs/
- **Config Documentation**: https://starship.rs/config/
- **Styling Documentation**: https://starship.rs/config/#style-strings
- **Advanced Config**: https://starship.rs/advanced-config/
- **Config Format**: TOML
- **Nix Integration**: `programs.starship.settings`
- **Color Schema**: Custom palette support
  ```toml
  palette = "signal"
  
  [palettes.signal]
  background = "#hex"
  foreground = "#hex"
  focus = "#hex"
  success = "#hex"
  warning = "#hex"
  danger = "#hex"
  # ... custom colors
  
  # Then reference in modules
  [character]
  success_symbol = "[❯](bold success)"
  error_symbol = "[❯](bold danger)"
  
  [directory]
  style = "bold focus"
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.starship.enable
- **Notes**: Supports custom palettes. Style strings can reference palette colors or use direct colors.

---

## Shells

### Zsh

- **Official Website**: https://www.zsh.org/
- **Documentation**: https://zsh.sourceforge.io/Doc/
- **Syntax Highlighting**: https://github.com/zsh-users/zsh-syntax-highlighting
- **Config Format**: Shell script
- **Nix Integration**: `programs.zsh.syntaxHighlighting.styles` or environment variables
- **Color Schema**: Via zsh-syntax-highlighting or prompt
  ```bash
  # Syntax highlighting styles
  typeset -A ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg=#hex'
  ZSH_HIGHLIGHT_STYLES[alias]='fg=#hex'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=#hex'
  ZSH_HIGHLIGHT_STYLES[function]='fg=#hex'
  ZSH_HIGHLIGHT_STYLES[comment]='fg=#hex'
  ZSH_HIGHLIGHT_STYLES[string]='fg=#hex'
  # ... etc
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable
- **Notes**: Theming mainly via syntax highlighting plugin and prompt customization.

---

## Monitors

### Btop

- **Official Website**: https://github.com/aristocratos/btop
- **Documentation**: https://github.com/aristocratos/btop#configurability
- **Theme Documentation**: https://github.com/aristocratos/btop/blob/main/themes/README.md
- **Config Format**: Custom .theme format
- **Nix Integration**: `programs.btop` or `xdg.configFile."btop/themes/signal.theme"`
- **Color Schema**:
  ```ini
  # Main background and foreground
  theme[main_bg]="#hex"
  theme[main_fg]="#hex"
  
  # Title
  theme[title]="#hex"
  
  # Inactive/active status
  theme[inactive_fg]="#hex"
  theme[selected_bg]="#hex"
  theme[selected_fg]="#hex"
  
  # Graphs
  theme[cpu_box]="#hex"
  theme[mem_box]="#hex"
  theme[net_box]="#hex"
  theme[proc_box]="#hex"
  
  # Graph colors
  theme[graph_text]="#hex"
  theme[meter_bg]="#hex"
  theme[proc_misc]="#hex"
  
  # ... many more elements
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.btop.enable
- **Notes**: Very detailed theming with many specific UI elements. Custom .theme file format.

---

## Desktop Applications

### Fuzzel (Application Launcher)

- **Official Website**: https://codeberg.org/dnkl/fuzzel
- **Documentation**: https://codeberg.org/dnkl/fuzzel/src/branch/master/doc/fuzzel.ini.5.scd
- **Config Format**: INI (via Nix attrs)
- **Nix Integration**: `programs.fuzzel.settings`
- **Color Schema**:
  ```nix
  programs.fuzzel.settings = {
    colors = {
      # Format: rrggbbaa (hex WITHOUT # prefix, includes alpha)
      background = "1a1c22f2";  # ~95% opacity
      text = "d8d8dcff";        # fully opaque
      match = "6b87c8ff";
      selection = "2a2c32ff";
      selection-text = "d8d8dcff";
      selection-match = "6b87c8ff";
      border = "6b87c8ff";
    };
    
    border = {
      width = 2;
      radius = 12;
    };
  };
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.fuzzel.enable
- **Notes**: 
  - Uses RRGGBBAA format (8-digit hex, no # prefix)
  - Alpha channel is required for all colors
  - FF = fully opaque, 00 = fully transparent
  - Colors are accessed via `signalColors.tonal."name".hexRaw` in signal-nix

---

## GTK Applications

### GTK Theme

- **Official Website**: https://www.gtk.org/
- **Theme Documentation**: https://docs.gtk.org/gtk4/css-properties.html
- **Config Format**: CSS (GTK CSS variant)
- **Nix Integration**: `gtk.theme` or custom CSS via `gtk.gtk3.extraCss` / `gtk.gtk4.extraCss`
- **Color Schema**: GTK CSS
  ```css
  @define-color theme_fg_color #hex;
  @define-color theme_bg_color #hex;
  @define-color theme_base_color #hex;
  @define-color theme_selected_bg_color #hex;
  @define-color theme_selected_fg_color #hex;
  @define-color borders #hex;
  @define-color warning_color #hex;
  @define-color error_color #hex;
  @define-color success_color #hex;
  
  /* Apply to widgets */
  window {
    background-color: @theme_bg_color;
    color: @theme_fg_color;
  }
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-gtk.enable
- **Notes**: GTK theming is complex. Can use pre-made themes or custom CSS overrides.

---

## Wayland Bars

### Ironbar

- **Official Website**: https://github.com/JakeStanger/ironbar
- **Documentation**: https://github.com/JakeStanger/ironbar/wiki
- **Styling Documentation**: https://github.com/JakeStanger/ironbar/wiki/styling-guide
- **Config Format**: JSON/YAML for config, CSS for styling
- **Nix Integration**: `programs.ironbar.config` and `programs.ironbar.style`
- **Color Schema**: GTK CSS
  ```css
  @define-color text_primary #hex;
  @define-color surface_base #hex;
  @define-color accent_focus #hex;
  
  #bar {
    background-color: @surface_base;
  }
  
  .workspaces button.focused {
    color: @text_primary;
    border-left-color: @accent_focus;
  }
  
  label {
    color: @text_primary;
  }
  ```
- **Home Manager Options**: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ironbar.enable
- **Notes**: Uses GTK CSS for styling. Widget structure defined in config, colors/styling in CSS.

---

## Summary Table

| Application | Format | Nix Integration | Color Format | Notes |
|------------|--------|-----------------|--------------|-------|
| Alacritty | TOML | `programs.alacritty.settings` | Hex | 16 ANSI + UI colors |
| Kitty | Custom | `programs.kitty.settings` | Hex | Very comprehensive |
| WezTerm | Lua | `programs.wezterm` | Hex (in Lua) | Programmable |
| Ghostty | INI | `xdg.configFile` | Hex | Newer terminal |
| Bat | tmTheme XML | `programs.bat.themes` | Hex | Sublime format |
| Delta | gitconfig | `programs.delta.options` | Hex or names | Uses bat themes |
| Eza | Env vars | Shell env | ANSI codes | `LS_COLORS` format |
| FZF | Flags | `programs.fzf.colors` | Hex or names | CLI flag format |
| Lazygit | YAML | `xdg.configFile` | Hex + attrs | Style attributes |
| Yazi | TOML | `programs.yazi` | Hex + attrs | Comprehensive |
| Helix | TOML | `programs.helix.themes` | Hex + palette | Two-level theming |
| Neovim | Lua/Vim | `programs.neovim` | Hex | Highlight groups |
| Tmux | Tmux cmd | `programs.tmux.extraConfig` | Hex | Set-option style |
| Zellij | KDL | `programs.zellij` | Hex | Custom DSL |
| Starship | TOML | `programs.starship.settings` | Hex + palette | Custom palettes |
| Zsh | Shell | `programs.zsh` | Hex (fg=) | Syntax highlighting |
| Btop | Custom | `xdg.configFile` | Hex | theme[] format |
| Fuzzel | INI | `programs.fuzzel.settings` | RRGGBBAA | With alpha |
| GTK | CSS | `gtk` module | Hex | GTK CSS format |
| Ironbar | CSS | `programs.ironbar` | Hex | GTK CSS |

---

## Nix-Specific Resources

- **Home Manager Options Search**: https://nix-community.github.io/home-manager/options.xhtml
- **NixOS Options Search**: https://search.nixos.org/options
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **NixOS Wiki**: https://wiki.nixos.org/

---

## Implementation Notes

### Common Patterns

1. **Terminal Emulators**: All use 16 ANSI colors + foreground/background + cursor + selection
2. **Syntax Highlighters**: Most use scope-based highlighting (comment, string, keyword, etc.)
3. **Home Manager**: Most tools have native home-manager modules with `.settings` or `.config` attributes
4. **Color Formats**: Nearly all accept hex colors (`#RRGGBB`), some support alpha (`#RRGGBBAA`)
5. **Nix Integration**: Prefer home-manager options when available, fall back to `xdg.configFile` for raw configs

### Verification Steps

For each application:
1. Check if home-manager module exists: `search.nixos.org`
2. Verify config format in official docs
3. Test with minimal color set first
4. Expand to full theme
5. Validate colors render correctly

---

## Maintenance

This document should be updated when:
- New applications are added to signal-nix
- Application configuration formats change
- New Nix integration methods become available
- Documentation URLs change or become outdated

Last Updated: 2026-01-17
