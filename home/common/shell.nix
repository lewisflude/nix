{
  pkgs,
  config,
  systemConfig,
  system,
  hostSystem,
  host,
  lib,
  inputs,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  # Import nvfetcher-generated sources for ZSH plugins
  sources = import ./_sources/generated.nix {
    inherit
      (pkgs)
      fetchgit
      fetchFromGitHub
      fetchurl
      dockerTools
      ;
  };
  # Use FULL Catppuccin palette - access all semantic colors directly
  # Uses catppuccin.nix module palette when available, falls back to direct input access
  palette =
    if lib.hasAttrByPath ["catppuccin" "sources" "palette"] config
    then
      # Use catppuccin.nix module palette if available
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else
      # Try to get palette directly from catppuccin input
      let
        catppuccinPalette =
          pkgs.lib.importJSON
          (inputs.catppuccin.packages.${system}.catppuccin-gtk-theme.src + "/palette.json").mocha.colors;
      in
        catppuccinPalette;
  secretAvailable = name: lib.hasAttrByPath ["sops" "secrets" name "path"] systemConfig;
  secretPath = name: lib.attrByPath ["sops" "secrets" name "path"] "" systemConfig;
  secretExportSnippet = name: var: let
    path = secretPath name;
  in
    lib.optionalString (secretAvailable name) ''
      if [ -r ${lib.escapeShellArg path} ]; then
        export ${var}="$(cat ${lib.escapeShellArg path})"
      fi
    '';
  # Zsh abbreviations configuration (declarative file-based approach)
  # Format: { abbreviation = "expansion"; }
  # zsh-abbr reads from a file in format: abbreviation=expansion
  zshAbbreviations = {
    "fid" = "Finished installing dependencies";
    "tpfd" = "There was a problem finishing installing dependencies";
  };
  # Generate zsh-abbr configuration file content
  # Format: abbr-name=expansion (one per line)
  zshAbbrConfigFile = lib.concatMapStringsSep "\n" ({
    abbr,
    expansion,
  }: "${abbr}=${expansion}") (
    lib.mapAttrsToList (abbr: expansion: {inherit abbr expansion;}) zshAbbreviations
  );
in {
  xdg.enable = true;
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
      defaultCommand = lib.mkDefault (
        if pkgs ? fd
        then "${lib.getExe pkgs.fd} --hidden --strip-cwd-prefix --exclude .git"
        else if pkgs ? ripgrep
        then "${lib.getExe pkgs.ripgrep} --files --hidden --follow --glob '!.git'"
        else null
      );
      fileWidgetCommand = lib.mkDefault (
        if pkgs ? fd
        then "${lib.getExe pkgs.fd} --type f --hidden --strip-cwd-prefix --exclude .git"
        else null
      );
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = ["--disable-up-arrow"];
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch.enable = true;
      plugins = [
        {
          name = "zsh-defer";
          inherit (sources.zsh-defer) src;
          file = "zsh-defer.plugin.zsh";
        }
        {
          name = "zsh-you-should-use";
          inherit (sources.zsh-you-should-use) src;
          file = "you-should-use.plugin.zsh";
        }
        {
          name = "zsh-autopair";
          inherit (sources.zsh-autopair) src;
          file = "autopair.zsh";
        }
        {
          name = "zsh-auto-notify";
          inherit (sources.zsh-auto-notify) src;
          file = "auto-notify.plugin.zsh";
        }
        {
          name = "zsh-abbr";
          inherit (sources.zsh-abbr) src;
          file = "zsh-abbr.zsh";
        }
        {
          name = "zsh-bd";
          inherit (sources.zsh-bd) src;
          file = "bd.zsh";
        }
      ];
      completionInit = ''
        setopt EXTENDED_GLOB
        autoload -Uz compinit
        if ! compaudit 2>/dev/null; then
          echo "Warning: Insecure zsh completion directories detected."
          echo "Attempting to fix ownership issues..."
          if [[ -d "/usr/local/share/zsh" ]] && [[ -O "/usr/local/share/zsh" ]]; then
            echo "Fixing /usr/local/share/zsh ownership..."
            sudo chown -R root:wheel /usr/local/share/zsh 2>/dev/null || true
          fi
        fi
        if [[ -f ${config.xdg.cacheHome}/zsh/.zcompdump ]]; then
          compinit
        else
          compinit -C
        fi
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
        zstyle ':completion:*' use-cache yes
        zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh
        _lazy_load_docker_completion() {
          if command -v docker &> /dev/null && [[ ! -f ${config.xdg.cacheHome}/zsh/docker_completion_loaded ]]; then
            source <(docker completion zsh) 2>/dev/null || true
            touch ${config.xdg.cacheHome}/zsh/docker_completion_loaded
          fi
        }
        _lazy_load_kubectl_completion() {
          if command -v kubectl &> /dev/null && [[ ! -f ${config.xdg.cacheHome}/zsh/kubectl_completion_loaded ]]; then
            source <(kubectl completion zsh) 2>/dev/null || true
            touch ${config.xdg.cacheHome}/zsh/kubectl_completion_loaded
          fi
        }
        _lazy_load_npm_completion() {
          if command -v npm &> /dev/null && [[ ! -f ${config.xdg.cacheHome}/zsh/npm_completion_loaded ]]; then
            source <(npm completion) 2>/dev/null || true
            touch ${config.xdg.cacheHome}/zsh/npm_completion_loaded
          fi
        }
        docker() { _lazy_load_docker_completion; unfunction docker; docker "$@"; }
        kubectl() { _lazy_load_kubectl_completion; unfunction kubectl; kubectl "$@"; }
        npm() { _lazy_load_npm_completion; unfunction npm; npm "$@"; }
        mkdir -p ${config.xdg.cacheHome}/zsh
      '';
      # Use dedicated autocd option instead of AUTO_CD in setOptions
      autocd = true;
      setOptions = [
        "AUTO_MENU"
        "COMPLETE_IN_WORD"
        "ALWAYS_TO_END"
        "HIST_VERIFY"
        "HIST_REDUCE_BLANKS"
        "HIST_IGNORE_SPACE"
        "HIST_NO_FUNCTIONS"
        "HIST_EXPIRE_DUPS_FIRST"
        "HIST_FIND_NO_DUPS"
        "HIST_SAVE_NO_DUPS"
        "HIST_BEEP"
        "BANG_HIST"
        "AUTO_PUSHD"
        "PUSHD_IGNORE_DUPS"
        "PUSHD_SILENT"
        "PUSHD_TO_HOME"
        "CDABLE_VARS"
        "MULTIOS"
        "EXTENDED_GLOB"
        "GLOB_DOTS"
        "GLOBSTARSHORT"
        "NUMERIC_GLOB_SORT"
        "MARK_DIRS"
        "NOMATCH"
        "CASE_GLOB"
        "BAD_PATTERN"
        "INTERACTIVE_COMMENTS"
        "LONG_LIST_JOBS"
        "NOTIFY"
        "HASH_LIST_ALL"
        "AUTO_LIST"
        "AUTO_PARAM_SLASH"
      ];
      # Set environment variables before plugins load (goes in .zshenv)
      envExtra = ''
        # Configure zsh-abbr to use our declarative abbreviations file
        export ABBR_USER_ABBREVIATIONS_FILE="${config.xdg.configHome}/zsh/abbreviations"
      '';
      # Zsh-specific session variables (better than home.sessionVariables)
      sessionVariables = {
        DIRSTACKSIZE = "20";
      };
      shellAliases = lib.mkMerge [
        {
          switch = platformLib.systemRebuildCommand {hostName = host.hostname;};
          update = "system-update";
          edit = "sudo -e";
          ls = "eza";
          l = "eza -l";
          la = "eza -la";
          lt = "eza --tree";
          ll = "eza -l --git --header";
          cd = "z";
          find = "fd";
          cat = "bat";
          top = "htop";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
          "....." = "cd ../../../..";
          d = "dirs -v";
          po = "popd";
          pu = "pushd";
          g = "git";
          gs = "git status";
          gd = "git diff";
          gc = "git commit";
          gp = "git push";
          gl = "git pull";
          gco = "git checkout";
          gb = "git branch";
          glog = "git log --oneline --graph --decorate";
          ports = "ss -tulanp || netstat -tulanp";
          myip = "curl -s ifconfig.me";
          nix-search = "nh search";
          nix-info = "nix-shell -p nix-info --run 'nix-info -m'";
          nix-size = "du -sh /nix/store";
          nix-update-lock = "nix flake update --flake ~/.config/nix";
          nh-os = "nh os";
          nh-home = "nh home";
          nh-darwin = "nh darwin";
          nh-clean = "nh clean all";
          dev = "nix develop ~/.config/nix";
          abbr-list = "abbr list";
          abbr-add = "abbr add";
          abbr-erase = "abbr erase";
          lsh = "eza -la .*";
          lsz = "eza -la ***.{js,ts,jsx,tsx,py,go,rs,c,cpp,h,hpp}";
          lsconfig = "eza -la **/*.{json,yaml,yml,toml,ini,conf,cfg}";
          zjls = "zellij list-sessions";
          zjk = "zellij kill-session";
          zja = "zellij attach";
          zjd = "zellij delete-session";
        }
        (lib.mkIf isLinux {
          lock = "saylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color cba6f7 --key-hl-color b4befe --line-color 00000000 --inside-color 1e1e2e88 --separator-color 00000000 --text-color cdd6f4 --grace 2 --fade-in 0.2";
        })
      ];
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
      # Use initContent with mkAfter to append after home-manager's defaults
      initContent = lib.mkAfter ''
        ${secretExportSnippet "KAGI_API_KEY" "KAGI_API_KEY"}
        ${secretExportSnippet "GITHUB_TOKEN" "GITHUB_TOKEN"}
        export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        # Arrays must be set in initContent, not localVariables
        typeset -ga ZSH_AUTOSUGGEST_STRATEGY
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${palette.mauve.hex},bg=${palette.surface1.hex},bold,underline"
        export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
        export SOPS_GPG_ARGS="--pinentry-mode=loopback"
        export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
        export NH_CLEAN_ARGS="--keep-since 4d --keep 3"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
        zsh-defer -c 'export YSU_MESSAGE_POSITION="after"'
        zsh-defer -c 'export YSU_HARDCORE=1'
        export AUTO_NOTIFY_THRESHOLD=10
        export AUTO_NOTIFY_TITLE="Command finished"
        export AUTO_NOTIFY_BODY="Completed in %elapsed seconds"
        export AUTO_NOTIFY_IGNORE=(
          "man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync"
          "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff"
        )
        export WORDCHARS='*?_-.[]~=&;!#'
        export ATUIN_NOBIND="true"
        zsh-defer -c 'bindkey "^r" _atuin_search_widget'
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^P' history-substring-search-up
        bindkey '^N' history-substring-search-down
        function _ghostty_insert_newline() { LBUFFER+=$'\n' }
        zle -N ghostty-insert-newline _ghostty_insert_newline
        bindkey -M emacs $'\e[99997u' ghostty-insert-newline
        bindkey -M viins $'\e[99997u' ghostty-insert-newline
        bindkey -M emacs $'\e\r'     ghostty-insert-newline
        bindkey -M viins $'\e\r'     ghostty-insert-newline
        zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*' squeeze-slashes true
        zstyle ':completion:*' list-colors '${"\${(s.:.)LS_COLORS}"}'
        zstyle ':completion:*' menu select
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' verbose true
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
        zstyle ':completion:*:corrections' format '%F{green}%d (errors: %e)%f'
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
        zstyle ':completion:*:*:kill:*' menu yes select
        zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
        zstyle ':completion:*:cd:*' ignore-parents parent pwd
        zstyle ':completion:*' file-patterns '%p:globbed-files *(-/):directories' '*:all-files'
        unsetopt FLOW_CONTROL
        if [[ ! -o interactive || ! -t 1 || "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
          unsetopt CORRECT CORRECT_ALL
        else
          setopt CORRECT
          unsetopt CORRECT_ALL
        fi
        zsh-defer -c 'if [[ ~/.zshrc -nt ~/.zshrc.zwc ]]; then zcompile ~/.zshrc; fi'
        if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh" ]]; then
          source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh"
        fi
        ${
          let
            zsh_codex = sources.zsh_codex.src;
          in ''
            if [[ -f "${zsh_codex}/zsh_codex.plugin.zsh" ]]; then
              source "${zsh_codex}/zsh_codex.plugin.zsh"
              bindkey '^X' create_completion
            fi
          ''
        }
        eval "$(zoxide init zsh)"
        # zsh-abbr storage file is configured via ABBR_USER_ABBREVIATIONS_FILE
        # which is set before the plugin loads (see plugins section)
        # The plugin will automatically load from that file
      '';
    };
  };
  home = {
    # Global session variables (affect all shells, not just zsh)
    sessionVariables = {
      EDITOR = "hx";
      NH_FLAKE = "${config.home.homeDirectory}/.config/nix";
    };
    file = {
      ".p10k.zsh".source = ./lib/p10k.zsh;
      # Declarative zsh-abbr configuration file
      # zsh-abbr will automatically load this file on initialization
      ".config/zsh/abbreviations".text = zshAbbrConfigFile;
    };
    packages = with pkgs; [
      zoxide
      (writeShellApplication {
        name = "system-update";
        runtimeInputs = [
          nh
          nix
          coreutils
        ];
        text = ''
                    set -Eeuo pipefail

                    FLAKE_PATH="''${NH_FLAKE:-${config.home.homeDirectory}/.config/nix}"
                    NH_TARGET=$([[ "$(uname)" == "Darwin" ]] && echo "darwin" || echo "os")

                    # Handle NoNewPrivs on Linux only
                    if [[ -r /proc/self/status ]] && [[ "$(awk '/NoNewPrivs/ {print $2}' /proc/self/status 2>/dev/null || echo 0)" == "1" ]]; then
                      if command -v systemd-run >/dev/null 2>&1; then
                        exec systemd-run --user --pty --same-dir --wait --collect -p NoNewPrivileges=no system-update "$@"
                      else
                        echo "NoNewPrivs=1 and systemd-run not found. Run from a non-sandboxed terminal or a VT." >&2
                        exit 1
                      fi
                    fi

                    # Parse flags
                    UPDATE_INPUTS=0 RUN_GC=0 BUILD_ONLY=0 DRY_RUN=0
                    for arg in "$@"; do
                      case "$arg" in
                        --full) UPDATE_INPUTS=1; RUN_GC=1 ;;
                        --inputs) UPDATE_INPUTS=1 ;;
                        --gc) RUN_GC=1 ;;
                        --build-only) BUILD_ONLY=1 ;;
                        --check|--dry-run) DRY_RUN=1 ;;
                        --help)
                          cat <<EOF
          Usage: system-update [OPTIONS]

          Options:
            --full          Update inputs, build/switch, and run garbage collection
            --inputs        Update flake inputs before building/switching
            --gc            Run garbage collection after build/switch
            --build-only    Build without switching (does not activate changes)
            --check, --dry-run  Validate configuration without building
            --help          Show this help message

          Examples:
            system-update              # Switch to current configuration
            system-update --full        # Update inputs, switch, and cleanup
            system-update --inputs     # Update inputs then switch
            system-update --build-only # Build without switching
          EOF
                          exit 0 ;;
                        *)
                          echo "Unknown option: $arg" >&2
                          echo "Run 'system-update --help' for usage information." >&2
                          exit 1 ;;
                      esac
                    done

                    # Validate mutually exclusive flags
                    if [[ $BUILD_ONLY -eq 1 ]] && [[ $DRY_RUN -eq 1 ]]; then
                      echo "Error: --build-only and --dry-run are mutually exclusive." >&2
                      exit 1
                    fi

                    # Execute operations
                    [[ $UPDATE_INPUTS -eq 1 ]] && echo "Updating inputs…" && nix flake update --flake "$FLAKE_PATH"

                    if [[ $DRY_RUN -eq 1 ]]; then
                      echo "Checking switch…"
                      nh "$NH_TARGET" switch --dry "$FLAKE_PATH"
                    elif [[ $BUILD_ONLY -eq 1 ]]; then
                      echo "Building…"
                      nh "$NH_TARGET" build "$FLAKE_PATH"
                    else
                      echo "Switching…"
                      nh "$NH_TARGET" switch "$FLAKE_PATH"
                    fi

                    # Skip GC on dry-run
                    [[ $RUN_GC -eq 1 ]] && [[ $DRY_RUN -eq 0 ]] && echo "Cleaning…" && nh clean all

                    echo "Done."
        '';
      })
      (writeShellApplication {
        name = "dev";
        runtimeInputs = with pkgs; [
          bash
          coreutils
          findutils
          git
          nix
          fzf
          jq
        ];
        text = ''
          CONFIG_ROOT="${config.home.homeDirectory}/.config/nix"
          echo "The 'dev' wrapper has been removed for simplicity."
          echo "Use direct commands or source $CONFIG_ROOT/scripts/ALIASES.sh for convenience aliases."
          echo ""
          echo "Common commands:"
          echo "  nix flake update              - Update flake.lock"
          echo "  darwin-rebuild switch         - Build & activate (macOS)"
          echo "  nh os switch                  - Build & activate (NixOS)"
          echo "  nix-collect-garbage -d        - Clean up old generations"
          echo ""
          echo "See: $CONFIG_ROOT/scripts/README.md"
        '';
      })
    ];
  };
  home.file.".config/direnv/lib/layout_zellij.sh".text = ''
    layout_zellij() {
      # Don't nest Zellij sessions
      if [ -n "$ZELLIJ" ]; then
        return 0
      fi

      # Use directory-based session names for better organization
      local session_name="$(basename "$PWD")"

      if [ -f ".zellij.kdl" ]; then
        # Custom layout for this project
        exec zellij --layout .zellij.kdl attach -c "$session_name"
      else
        # Standard layout with named session
        exec zellij attach -c "$session_name"
      fi
    }
  '';
}
