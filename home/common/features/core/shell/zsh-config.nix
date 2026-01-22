# ZSH Core Configuration
# Basic ZSH options, settings, and directory configuration
{
  config,
  lib,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    # Disabled: eager loading defeats lazy loading with zsh-defer
    # These are now manually sourced with proper ordering in initContent
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    historySubstringSearch.enable = false;

    autocd = true;
    setOptions = [
      "AUTO_MENU"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "AUTO_LIST"
      "AUTO_PARAM_SLASH"

      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "PUSHD_TO_HOME"
      "CDABLE_VARS"

      "EXTENDED_GLOB"
      "GLOB_DOTS"
      "GLOBSTARSHORT"
      "NUMERIC_GLOB_SORT"
      "MARK_DIRS"
      "NOMATCH"
      "CASE_GLOB"
      "BAD_PATTERN"

      "MULTIOS"
      "INTERACTIVE_COMMENTS"
      "LONG_LIST_JOBS"
      "NOTIFY"
      "HASH_LIST_ALL"
    ];

    sessionVariables = {
      DIRSTACKSIZE = "20";
      NH_SEARCH_CHANNEL = "nixpkgs-unstable";
    };

    # Local variables defined at the top of .zshrc (not exported as environment vars)
    localVariables = {
      # Zsh autosuggestions configuration
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=240";

      # Auto-notify configuration
      AUTO_NOTIFY_THRESHOLD = 10;
      AUTO_NOTIFY_TITLE = "Command finished";
      AUTO_NOTIFY_BODY = "Completed in %elapsed seconds";

      # Atuin configuration
      ATUIN_NOBIND = "true";
    };

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

    # Explicitly set keymap (emacs mode)
    defaultKeymap = "emacs";

    # Enable VTE terminal integration (consistency with system config)
    # Supports GNOME Terminal, Tilix, and other VTE-based terminals
    enableVteIntegration = true;

    # zprof: Profiling is enabled via zmodload at top of .zshrc
    # Auto-display disabled - run 'zprof' manually to see performance breakdown

    # Set arrays that must be defined before plugins load
    # Arrays are not supported in localVariables, so set here
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
}
