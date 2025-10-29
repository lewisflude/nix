{
  pkgs,
  config,
  systemConfig,
  system,
  hostSystem,
  host,
  lib,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
  isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  palette =
    if lib.hasAttrByPath ["catppuccin" "sources" "palette"] config
    then (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${config.catppuccin.flavor}.colors
    else {
      mauve = {
        hex = "b48ead";
      };
      surface1 = {
        hex = "3b4252";
      };
    };
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
          src = pkgs.fetchFromGitHub {
            owner = "romkatv";
            repo = "zsh-defer";
            rev = "53a26e287fbbe2dcebb3aa1801546c6de32416fa";
            sha256 = "sha256-MFlvAnPCknSgkW3RFA8pfxMZZS/JbyF3aMsJj9uHHVU=";
          };
          file = "zsh-defer.plugin.zsh";
        }
        {
          name = "zsh-you-should-use";
          src = pkgs.fetchFromGitHub {
            owner = "MichaelAquilina";
            repo = "zsh-you-should-use";
            rev = "1.7.3";
            sha256 = "sha256-/uVFyplnlg9mETMi7myIndO6IG7Wr9M7xDFfY1pG5Lc=";
          };
          file = "you-should-use.plugin.zsh";
        }
        {
          name = "zsh-autopair";
          src = pkgs.fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "396c38a7468458ba29011f2ad4112e4fd35f78e6";
            sha256 = "sha256-PXHxPxFeoYXYMOC29YQKDdMnqTO0toyA7eJTSCV6PGE=";
          };
          file = "autopair.zsh";
        }
        {
          name = "zsh-auto-notify";
          src = pkgs.fetchFromGitHub {
            owner = "MichaelAquilina";
            repo = "zsh-auto-notify";
            rev = "master";
            sha256 = "sha256-s3TBAsXOpmiXMAQkbaS5de0t0hNC1EzUUb0ZG+p9keE=";
          };
          file = "auto-notify.plugin.zsh";
        }
        {
          name = "zsh-abbr";
          src = pkgs.fetchFromGitHub {
            owner = "olets";
            repo = "zsh-abbr";
            rev = "v5.8.0";
            sha256 = "sha256-bsacP1f1daSYfgMvXduWQ64JJXnrFiLYURENKSMA9LM=";
          };
          file = "zsh-abbr.zsh";
        }
        {
          name = "zsh-bd";
          src = pkgs.fetchFromGitHub {
            owner = "Tarrasch";
            repo = "zsh-bd";
            rev = "d4a55e661b4c9ef6ae4568c6abeff48bdf1b1af7";
            sha256 = "sha256-iznyTYDvFr1wuDZVwd1VTcB179SZQ2L0ZSY9g7BFDgg=";
          };
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
        if [[ -n ${config.xdg.cacheHome}/zsh/.zcompdump ]]; then
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
        "AUTO_CD"
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
      initContent = ''
        ${secretExportSnippet "KAGI_API_KEY" "KAGI_API_KEY"}
        ${secretExportSnippet "GITHUB_TOKEN" "GITHUB_TOKEN"}
        export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
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
            zsh_codex = pkgs.fetchFromGitHub {
              owner = "tom-doerr";
              repo = "zsh_codex";
              rev = "6ede649f1260abc5ffe91ef050d00549281dc461";
              sha256 = "sha256-m3m+ErBakBMrBsoiYgI8AdJZwXgcpz4C9hIM5Q+6lO4=";
            };
          in ''
            if [[ -f "${zsh_codex}/zsh_codex.plugin.zsh" ]]; then
              source "${zsh_codex}/zsh_codex.plugin.zsh"
              bindkey '^X' create_completion
            fi
          ''
        }
        eval "$(zoxide init zsh)"
      '';
    };
  };
  home = {
    sessionVariables = {
      EDITOR = "hx";
      DIRSTACKSIZE = "20";
      NH_FLAKE = "${config.home.homeDirectory}/.config/nix";
    };
    file = {
      ".p10k.zsh".source = ./lib/p10k.zsh;
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
          IFS=$'\n\t'
          FLAKE_PATH="''${NH_FLAKE:-${config.home.homeDirectory}/.config/nix}"
          NH_TARGET="${
            if isDarwin
            then "darwin"
            else "os"
          }"
          if [ "$(awk '/NoNewPrivs/ {print $2}' /proc/self/status 2>/dev/null || echo 0)" = "1" ]; then
            if command -v systemd-run >/dev/null 2>&1; then
              echo "Detected NoNewPrivs=1; re-executing via systemd-run to allow sudo…"
              exec systemd-run --user --pty --same-dir --wait --collect -p NoNewPrivileges=no system-update "$@"
            else
              echo "NoNewPrivs=1 and systemd-run not found. Run from a non-sandboxed terminal or a VT."
              exit 1
            fi
          fi
          UPDATE_INPUTS=0
          RUN_GC=0
          BUILD_ONLY=0
          DRY_RUN=0
          for arg in "$@"; do
            case "$arg" in
              --full) UPDATE_INPUTS=1; RUN_GC=1 ;;
              --inputs) UPDATE_INPUTS=1 ;;
              --gc) RUN_GC=1 ;;
              --build-only) BUILD_ONLY=1 ;;
              --check|--dry-run) DRY_RUN=1 ;;
              --help)
                echo "Usage: system-update [--full|--inputs|--gc|--build-only|--check|--help]"
                exit 0 ;;
            esac
          done
          if [[ $UPDATE_INPUTS -eq 1 ]]; then
            echo "Updating inputs…"
            nix flake update --flake "$FLAKE_PATH"
          fi
          if [[ $DRY_RUN -eq 1 ]]; then
            echo "Checking switch…"
            nh "$NH_TARGET" switch -- --dry-run "$FLAKE_PATH"
          else
            if [[ $BUILD_ONLY -eq 1 ]]; then
              echo "Building…"
              nh "$NH_TARGET" build "$FLAKE_PATH"
            else
              echo "Switching…"
              nh "$NH_TARGET" switch "$FLAKE_PATH"
            fi
          fi
          if [[ $RUN_GC -eq 1 ]]; then
            echo "Cleaning…"
            nh clean all
          fi
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
