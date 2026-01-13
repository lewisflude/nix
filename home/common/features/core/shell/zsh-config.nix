# ZSH Core Configuration
# Basic ZSH options, settings, and directory configuration
{
  config,
  # pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  xdg.enable = true;
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
    };

    history = {
      save = 50000;
      size = 50000;
      ignoreAllDups = true;
      path = "${platformLib.homeDir config.home.username}/.zsh_history";
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
  };
}
