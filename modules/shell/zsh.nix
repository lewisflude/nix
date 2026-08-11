# Zsh — the shell itself, across every configuration class.
#
# ── .zshrc ordering contract ────────────────────────────────────────────────
# Everything order-sensitive is decided HERE and nowhere else. Sibling modules
# in this directory contribute through programs.zsh.* options rather than raw
# initContent, so that this table stays authoritative.
#
#   100   agent-shell guard      must precede everything, including any output
#   150   p10k instant prompt    must precede any output or stdin read (prompt.nix)
#   500   zsh-defer              mkBefore; everything else defers through it
#   ~550  fpath then compinit    completionInit; fpath MUST precede compinit
#   1000  home-manager's own     fzf / direnv / atuin / gpg-agent integrations
#   1500  binds, functions, defer  mkAfter; needs the fully built environment
#
# The 550 slot is why zsh-completions works at all: the previous layout added it
# to fpath from a mkAfter block, ~300 lines after compinit had already run, so
# those completions were never loaded.
{ config, ... }:
let
  inherit (config) username;

  # zsh-auto-notify is not packaged in nixpkgs; everything else here is.
  zshAutoNotify =
    { fetchgit }:
    fetchgit {
      url = "https://github.com/MichaelAquilina/zsh-auto-notify.git";
      rev = "b51c934d88868e56c1d55d0a2a36d559f21cb2ee";
      sha256 = "sha256-s3TBAsXOpmiXMAQkbaS5de0t0hNC1EzUUb0ZG+p9keE=";
    };
in
{
  # ═══════════════════════════════════════════════════════════════════
  # NixOS system-level shell configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.nixos.shell =
    { pkgs, ... }:
    {
      programs.zsh = {
        enable = true;
        # home-manager owns compinit (see completionInit below). Running it from
        # /etc/zshrc as well regenerates the dump on every single startup,
        # because fpath differs between the two calls.
        enableGlobalCompInit = false;
      };
      users.users.${username}.shell = pkgs.zsh;
      environment.shells = [ pkgs.zsh ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Darwin system-level shell configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.darwin.shell =
    { pkgs, ... }:
    {
      programs.zsh = {
        enable = true;
        enableGlobalCompInit = false;
      };
      # Darwin cannot point at a store path here: the login shell must be a
      # stable path that survives generation switches.
      users.users.${username}.shell = "/run/current-system/sw/bin/zsh";
      environment.shells = [ pkgs.zsh ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Home-manager shell configuration (works on NixOS AND Darwin)
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.homeManager.shell =
    hmArgs@{ lib, pkgs, ... }:
    let
      hmConfig = hmArgs.config;
      autoNotify = zshAutoNotify { inherit (pkgs) fetchgit; };
    in
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        dotDir = "${hmConfig.xdg.configHome}/zsh";

        # These four are sourced by hand under zsh-defer at order 1500, so the
        # prompt appears before they load. Leave them off here.
        autosuggestion.enable = false;
        syntaxHighlighting.enable = false;
        historySubstringSearch.enable = false;

        autocd = true;
        defaultKeymap = "emacs";
        enableVteIntegration = true;

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
        ];

        history = {
          # XDG state, not $HOME — history is state, not config.
          path = "${hmConfig.xdg.stateHome}/zsh/history";
          size = 50000;
          save = 50000;
          # HIST_IGNORE_ALL_DUPS subsumes ignoreDups and makes
          # expireDuplicatesFirst a no-op. Do not re-add either.
          ignoreAllDups = true;
          ignoreSpace = true;
          share = true;
          extended = true;
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
        };

        dirHashes = {
          nix = "$HOME/.config/nix";
          dots = "$HOME/.config";
        };
        cdpath = [
          "~/.config"
          "~/projects"
        ];

        localVariables = {
          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=240";
          AUTO_NOTIFY_THRESHOLD = 10;
          AUTO_NOTIFY_TITLE = "Command finished";
          AUTO_NOTIFY_BODY = "Completed in %elapsed seconds";
          # Suppresses every atuin binding; ^r is bound explicitly at order 1500
          # so that it lands after fzf's own ^r binding.
          ATUIN_NOBIND = "true";
        };

        sessionVariables = {
          DIRSTACKSIZE = "20";
          NH_SEARCH_CHANNEL = "nixpkgs-unstable";
          SYSTEMD_LESS = "FRSXMK --use-color";
        };

        # .zshenv — runs for every zsh process, including non-interactive ones.
        # Nothing secret belongs here; see secrets.nix.
        envExtra = ''
          export WORDCHARS='*?_-.[]~=&;!'
          export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
          export SOPS_GPG_ARGS="--pinentry-mode=loopback"
          export NIX_FLAKE="${hmConfig.home.homeDirectory}/.config/nix"
        '';

        completionInit = ''
          fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)

          autoload -Uz compinit
          () {
            emulate -L zsh -o extended_glob
            typeset -g _zcompdump="${hmConfig.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
            [[ -d ''${_zcompdump:h} ]] || mkdir -p ''${_zcompdump:h}
            # Dump newer than 24h: trust it and skip the fpath security scan.
            [[ -n ''${_zcompdump}(#qN.mh-24) ]] && typeset -g _zcompdump_fresh=1
          }
          if (( ''${_zcompdump_fresh:-0} )); then
            compinit -C -d "$_zcompdump"
          else
            compinit -d "$_zcompdump"
          fi
          unset _zcompdump _zcompdump_fresh

          source ${./zsh/completion-styles.zsh}
        '';

        initContent = lib.mkMerge [
          (lib.mkOrder 100 ''
            # Agent shells want a bare shell; bail out before anything else runs.
            if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
              return
            fi
          '')

          (lib.mkBefore ''
            source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
          '')

          (lib.mkAfter ''
            unsetopt FLOW_CONTROL

            source ${./zsh/keybindings.zsh}
            source ${./zsh/functions.zsh}
            source ${./zsh/ssh-columns.zsh}

            ZSH_AUTOSUGGEST_STRATEGY=(history completion)
            AUTO_NOTIFY_IGNORE=(man less more vim nano btop top ssh scp rsync
                                watch tail sleep ping curl wget "git log" "git diff")

            zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            zsh-defer source ${autoNotify}/auto-notify.plugin.zsh
            zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
            typeset -gA ZSH_HIGHLIGHT_STYLES
            zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

            # Diagnostics only — never needed to reach a prompt.
            zsh-defer source ${./zsh/p10k-diagnostics.zsh}

            # Plugin bindings, deferred so they run after the plugins above.
            if [[ -o interactive ]]; then
              zsh-defer -c 'bindkey "^r" _atuin_search_widget'
              zsh-defer -c 'bindkey "^P" history-substring-search-up'
              zsh-defer -c 'bindkey "^N" history-substring-search-down'
            fi
          '')
        ];
      };

      home.sessionVariables = {
        # Left in place deliberately: nix-darwin and the nix-daemon set this on
        # their own hosts, but removing it risks silent TLS breakage elsewhere.
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        # NIX_SSL_CERT_FILE is Nix-specific. OpenSSL and Python's `ssl` read
        # SSL_CERT_FILE, and uv's standalone CPython otherwise resolves its
        # default CA path to /etc/ssl/cert.pem, which does not exist on NixOS —
        # so anything verifying against the system store (rather than vendoring
        # certifi, as requests and httpx do) fails with
        # CERTIFICATE_VERIFY_FAILED. The uvx MCP wrappers set this themselves
        # via aiCli.uvxEnv, since they are launched outside this shell; this
        # covers everything else that runs from an interactive session.
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        EDITOR = "hx";
        VISUAL = "hx";
        COLORTERM = "truecolor";
        CLICOLOR = "1";
      };
    };
}
