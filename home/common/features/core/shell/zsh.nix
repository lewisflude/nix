# ZSH Declarative Configuration
# Single source of truth for all declarative ZSH settings
# Dendritic pattern: Uses pkgs.stdenv for platform detection instead of hostSystem
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Use pkgs.stdenv for platform detection instead of hostSystem parameter
  isLinux = pkgs.stdenv.isLinux;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";

    # Disabled: eager loading defeats lazy loading with zsh-defer
    # These are now manually sourced with proper ordering in zsh-init.nix
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    historySubstringSearch.enable = false;

    # ════════════════════════════════════════════════════════════════
    # Core ZSH Options
    # ════════════════════════════════════════════════════════════════

    autocd = true;
    defaultKeymap = "emacs";
    enableVteIntegration = true;

    setOptions = [
      # Completion
      "AUTO_MENU"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "AUTO_LIST"
      "AUTO_PARAM_SLASH"

      # Directory navigation
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "PUSHD_TO_HOME"
      "CDABLE_VARS"

      # Globbing
      "EXTENDED_GLOB"
      "GLOB_DOTS"
      "GLOBSTARSHORT"
      "NUMERIC_GLOB_SORT"
      "MARK_DIRS"
      "NOMATCH"
      "CASE_GLOB"
      "BAD_PATTERN"

      # Miscellaneous
      "MULTIOS"
      "INTERACTIVE_COMMENTS"
      "LONG_LIST_JOBS"
      "NOTIFY"
      "HASH_LIST_ALL"
    ];

    # ════════════════════════════════════════════════════════════════
    # History Configuration
    # ════════════════════════════════════════════════════════════════

    history = {
      save = 50000;
      size = 50000;
      ignoreAllDups = true;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignorePatterns = [
        "rm *"
        "pkill *"
        "cp *"
        "history*"
        "exit"
        "ls"
        "cd"
        "pwd"
        "clear"
      ];
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # ════════════════════════════════════════════════════════════════
    # Directory Navigation
    # ════════════════════════════════════════════════════════════════

    # Named directory hashes for quick navigation
    # Usage: cd ~nix, cd ~dots
    dirHashes = {
      nix = "$HOME/.config/nix";
      dots = "$HOME/.config";
    };

    # Paths to search for cd command (allows 'cd nix' without full path)
    cdpath = [
      "~/.config"
      "~/projects"
    ];

    # ════════════════════════════════════════════════════════════════
    # Shell Aliases
    # ════════════════════════════════════════════════════════════════

    shellAliases = lib.mkMerge [
      {
        # System rebuild
        switch = if isLinux then "nh os switch" else "nh darwin switch";

        # Core utilities
        edit = "sudo -e";
        ls = "eza";
        l = "eza -l";
        la = "eza -la";
        lt = "eza --tree";
        ll = "eza -l --git --header";
        find = "fd";
        cat = "bat";
        top = "htop";

        # Directory navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        d = "dirs -v";
        po = "popd";
        pu = "pushd";

        # Git shortcuts
        g = "git";
        gs = "git status";
        gd = "git diff";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gco = "git checkout";
        gb = "git branch";
        glog = "git log --oneline --graph --decorate";

        # Network utilities
        ports = "ss -tulanp || netstat -tulanp";
        myip = "curl -s ifconfig.me";

        # Nix commands (with glob disabling for '#')
        nix = "noglob nix";
        nix-build = "noglob nix build";
        nix-run = "noglob nix run";
        nix-develop = "noglob nix develop";
        nix-shell = "noglob nix-shell";
        nix-search = "nh search";
        nix-info = ", nix-info -m";
        nix-size = "du -sh /nix/store";
        nix-update-lock = "nix flake update --flake ~/.config/nix";

        # nh (Nix Helper) commands
        nh-os = "nh os";
        nh-home = "nh home";
        nh-darwin = "nh darwin";
        nh-clean = "nh clean all $NH_CLEAN_ARGS";
        nh-clean-old = "nh clean all --keep-since 7d --keep 5";
        nh-clean-aggressive = "nh clean all --keep-since 1d --keep 1";
        nh-list = "nh os list";
        nh-rollback = "nh os rollback";
        nh-diff = "nh os diff";
        nh-build = "nh os build";
        nh-build-dry = "nh os build --dry";
        nh-switch-dry = "nh os switch --dry";
        nh-check-all = "nix flake check --show-trace ~/.config/nix";
        nh-eval-system = "sudo nixos-rebuild build --show-trace --flake ~/.config/nix";

        # File listing shortcuts
        lsh = "eza -la .*";
        lsz = "eza -la ***.{js,ts,jsx,tsx,py,go,rs,c,cpp,h,hpp}";
        lsconfig = "eza -la **/*.{json,yaml,yml,toml,ini,conf,cfg}";

        # Zellij shortcuts
        zjls = "zellij list-sessions";
        zjk = "zellij kill-session";
        zja = "zellij attach";
        zjd = "zellij delete-session";

        # Editor
        zed = "zeditor";
      }
      (lib.mkIf isLinux {
        lock = "swaylock -f";
      })
    ];

    # Global aliases expand anywhere in a command line
    # Usage: dmesg G error → dmesg | grep error
    shellGlobalAliases = {
      G = "| grep";
      GI = "| grep -i";
      L = "| less";
      H = "| head";
      T = "| tail";
      J = "| jq";
      NUL = ">/dev/null 2>&1";
      NE = "2>/dev/null";
    };

    # ════════════════════════════════════════════════════════════════
    # Local Variables (not exported to environment)
    # ════════════════════════════════════════════════════════════════

    localVariables = {
      # Zsh autosuggestions
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=240";

      # Auto-notify
      AUTO_NOTIFY_THRESHOLD = 10;
      AUTO_NOTIFY_TITLE = "Command finished";
      AUTO_NOTIFY_BODY = "Completed in %elapsed seconds";

      # Atuin
      ATUIN_NOBIND = "true";
    };

    # ════════════════════════════════════════════════════════════════
    # Session Variables
    # ════════════════════════════════════════════════════════════════

    sessionVariables = {
      DIRSTACKSIZE = "20";
      NH_SEARCH_CHANNEL = "nixpkgs-unstable";

      # Systemd pager configuration
      # less 685+ supports 24-bit RGB colors with --use-color flag
      # This preserves systemd's full color palette (including severity-based coloring)
      # FRSXMK = standard systemd flags + --use-color for RGB support
      SYSTEMD_LESS = "FRSXMK --use-color";
    };

    # ════════════════════════════════════════════════════════════════
    # Environment Variables (.zshenv)
    # ════════════════════════════════════════════════════════════════
    # Sourced by ALL shells (interactive, non-interactive, login)
    # Should not produce output or assume TTY attachment

    envExtra = ''
      # Word characters for word-based navigation (Ctrl+W, Alt+B, etc.)
      # Excludes '/' so path components are treated as separate words
      export WORDCHARS='*?_-.[]~=&;!'

      # SOPS (secrets management)
      export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
      export SOPS_GPG_ARGS="--pinentry-mode=loopback"

      # Nix flake location
      export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
    '';

    # ════════════════════════════════════════════════════════════════
    # Completion System Initialization
    # ════════════════════════════════════════════════════════════════

    completionInit = ''
      # Initialize completion system with aggressive caching
      autoload -Uz compinit

      # Ensure cache directory exists
      mkdir -p ${config.xdg.cacheHome}/zsh

      # Add zsh-completions to fpath before compinit
      fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

      # Cache compinit dump - aggressively skip compaudit for faster startup
      # This dramatically speeds up shell startup (saves ~26ms from compaudit)
      local zcompdump="${config.xdg.cacheHome}/zsh/.zcompdump"

      # Only regenerate if dump doesn't exist or is older than 24 hours
      # Always use -C flag (skip compaudit) when dump is fresh
      if [[ ! -f "$zcompdump" ]] || [[ -n "$(find "$zcompdump" -mtime +1 2>/dev/null)" ]]; then
        # Dump doesn't exist or is old (>24hrs), regenerate with full checks
        compinit -d "$zcompdump"
      else
        # Dump is fresh, skip expensive compaudit security check
        compinit -C -d "$zcompdump"
      fi

      # Enable completion caching for expensive completions (e.g., package managers)
      zstyle ':completion:*' use-cache yes
      zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh
    '';

    # ════════════════════════════════════════════════════════════════
    # Array Variables (initContent)
    # ════════════════════════════════════════════════════════════════
    # Arrays must be set in initContent (not supported in localVariables)

    initContent = ''
      # Zsh autosuggestions strategy (array format required)
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)

      # Auto-notify ignore list (array format required by plugin)
      AUTO_NOTIFY_IGNORE=(
        "man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync"
        "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff"
      )
    '';
  };

  # ════════════════════════════════════════════════════════════════
  # Home Manager Configuration
  # ════════════════════════════════════════════════════════════════

  home = {
    sessionVariables = {
      # Nix SSL certificates
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      # Editor
      EDITOR = "hx";

      # Terminal color support
      COLORTERM = "truecolor";
      CLICOLOR = "1";

      # Direnv performance optimizations
      DIRENV_LOG_FORMAT = "";
      DIRENV_WARN_TIMEOUT = "20s";
      DIRENV_TIMEOUT = "5s";
    };

    packages = [
      pkgs.zoxide
    ];
  };

  # ════════════════════════════════════════════════════════════════
  # Direnv Layout File
  # ════════════════════════════════════════════════════════════════

  home.file.".config/direnv/lib/layout_zellij.sh".text = ''
    layout_zellij() {

      if [ -n "$ZELLIJ" ]; then
        return 0
      fi


      local session_name="$(basename "$PWD")"

      if [ -f ".zellij.kdl" ]; then

        exec zellij --layout .zellij.kdl attach -c "$session_name"
      else

        exec zellij attach -c "$session_name"
      fi
    }
  '';
}
