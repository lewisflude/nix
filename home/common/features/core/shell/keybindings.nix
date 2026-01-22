# ZSH Keybindings Configuration
# Terminfo-based key bindings with application mode support for maximum terminal compatibility
{ config, lib, ... }:
{
  programs.zsh.initContent = lib.mkMerge [
    # Terminfo bindings can be loaded early (don't depend on plugins)
    ''
      # ════════════════════════════════════════════════════════════════
      # Terminfo-Based Keybindings (Cross-Terminal Compatibility)
      # ════════════════════════════════════════════════════════════════
      # Use terminfo capabilities instead of hardcoded escape sequences
      # This ensures keybindings work across different terminal emulators

      # Create zkbd-compatible hash for key definitions
      typeset -g -A key

      # Populate key array with terminfo values
      key[Home]="''${terminfo[khome]}"
      key[End]="''${terminfo[kend]}"
      key[Insert]="''${terminfo[kich1]}"
      key[Backspace]="''${terminfo[kbs]}"
      key[Delete]="''${terminfo[kdch1]}"
      key[Up]="''${terminfo[kcuu1]}"
      key[Down]="''${terminfo[kcud1]}"
      key[Left]="''${terminfo[kcub1]}"
      key[Right]="''${terminfo[kcuf1]}"
      key[PageUp]="''${terminfo[kpp]}"
      key[PageDown]="''${terminfo[knp]}"
      key[Shift-Tab]="''${terminfo[kcbt]}"

      # Extended keys with modifiers (xterm-compatible terminals)
      key[Control-Left]="''${terminfo[kLFT5]}"
      key[Control-Right]="''${terminfo[kRIT5]}"
      key[Control-Delete]="''${terminfo[kDC5]}"

      # Setup key bindings (only if terminfo value exists)
      [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
      [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
      [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
      [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
      [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
      [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         up-line-or-history
      [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
      [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
      [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
      [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
      [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
      [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete

      # Word navigation with Ctrl+Arrow (xterm-compatible)
      [[ -n "''${key[Control-Left]}"  ]] && bindkey -- "''${key[Control-Left]}"  backward-word
      [[ -n "''${key[Control-Right]}" ]] && bindkey -- "''${key[Control-Right]}" forward-word

      # Ctrl+H for backward-kill-word (standard across terminals)
      bindkey '^H' backward-kill-word

      # Ctrl+Delete for kill-word (with fallback)
      [[ -n "''${key[Control-Delete]}" ]] && bindkey -- "''${key[Control-Delete]}" kill-word

      # ════════════════════════════════════════════════════════════════
      # Application Mode (Terminal State Management)
      # ════════════════════════════════════════════════════════════════
      # Ensure terminal is in application mode when ZLE is active
      # This makes terminfo values valid and keybindings work correctly

      if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
        autoload -Uz add-zle-hook-widget

        function zle_application_mode_start { echoti smkx }
        function zle_application_mode_stop { echoti rmkx }

        add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
        add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
      fi

      # Ghostty multiline input support (terminal-specific, doesn't depend on plugins)
      function _ghostty_insert_newline() { LBUFFER+=$'\n' }
      zle -N ghostty-insert-newline _ghostty_insert_newline
      bindkey -M emacs $'\e[99997u' ghostty-insert-newline
      bindkey -M viins $'\e[99997u' ghostty-insert-newline
      bindkey -M emacs $'\e\r'     ghostty-insert-newline
      bindkey -M viins $'\e\r'     ghostty-insert-newline
    ''

    # Plugin-specific bindings must be loaded AFTER zsh-defer is sourced
    # Use lib.mkAfter to ensure this comes after init-content.nix's lib.mkAfter section
    (lib.mkAfter ''
      # ════════════════════════════════════════════════════════════════
      # Plugin-Specific Keybindings (Deferred Loading)
      # ════════════════════════════════════════════════════════════════
      # These are loaded after plugins are initialized and zsh-defer is available

      if [[ -o interactive ]]; then
        # Atuin: Ctrl+R for history search (overwrites default)
        zsh-defer -c 'bindkey "^r" _atuin_search_widget'

        # History Substring Search: Ctrl+P/N (avoids Atuin conflict)
        zsh-defer -c 'bindkey "^P" history-substring-search-up'
        zsh-defer -c 'bindkey "^N" history-substring-search-down'
      fi
    '')
  ];
}
