{
  pkgs,
  config,
  system,
  lib,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
  palette =
    (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
    .${config.catppuccin.flavor}.colors;
in
{
  xdg.enable = true;

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      dotDir = ".config/zsh";

      autosuggestion = {
        enable = true;
        strategy = [ "history" "completion" ];
        highlight = "fg=${palette.mauve.hex},bg=${palette.surface1.hex},bold,underline";
      };

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
        if [[ -n ${config.xdg.cacheHome}/zsh/.zcompdump(#qN.mh+24) ]]; then
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
        "AUTO_MENU" "COMPLETE_IN_WORD" "ALWAYS_TO_END"
        "HIST_VERIFY" "HIST_REDUCE_BLANKS" "HIST_IGNORE_SPACE"
        "HIST_NO_FUNCTIONS" "HIST_EXPIRE_DUPS_FIRST" "HIST_FIND_NO_DUPS"
        "HIST_SAVE_NO_DUPS" "HIST_BEEP" "BANG_HIST"
        "AUTO_PUSHD" "PUSHD_IGNORE_DUPS" "PUSHD_SILENT" "PUSHD_TO_HOME"
        "CDABLE_VARS" "AUTO_CD" "MULTIOS"
        "EXTENDED_GLOB" "GLOB_DOTS" "GLOBSTARSHORT" "NUMERIC_GLOB_SORT"
        "MARK_DIRS" "NOMATCH" "CASE_GLOB" "BAD_PATTERN"
        "INTERACTIVE_COMMENTS" "LONG_LIST_JOBS" "NOTIFY" "HASH_LIST_ALL"
        "AUTO_LIST" "AUTO_PARAM_SLASH"
      ];

      shellAliases = lib.mkMerge [
        {
          switch = platformLib.systemRebuildCommand;
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
          ports = "netstat -tulanp";
          myip = "curl -s ifconfig.me";
          nix-search = "nh search";
          nix-info = "nix-shell -p nix-info --run 'nix-info -m'";
          nix-size = "du -sh /nix/store";
          nh-os = "nh os";
          nh-home = "nh home";
          nh-darwin = "nh darwin";
          nh-clean = "nh clean all";
          dev = "nix develop ~/.config/nix#shell-selector";
          abbr-list = "abbr list";
          abbr-add = "abbr add";
          abbr-erase = "abbr erase";
          lsh = "eza -la .*";
          lsz = "eza -la **/*.{zip,tar,gz,bz2,xz,7z}";
          lscode = "eza -la **/*.{js,ts,jsx,tsx,py,go,rs,c,cpp,h,hpp}";
          lsconfig = "eza -la **/*.{json,yaml,yml,toml,ini,conf,cfg}";
        }
        (lib.mkIf pkgs.stdenv.isLinux {
          lock = "swaylock --screenshots --clock --indicator --indicator-radius 100 --indicator-thickness 7 --effect-blur 7x5 --effect-vignette 0.5:0.5 --ring-color cba6f7 --key-hl-color b4befe --line-color 00000000 --inside-color 1e1e2e88 --separator-color 00000000 --text-color cdd6f4 --grace 2 --fade-in 0.2";
        })
      ];

      history = {
        save = 50000;
        size = 50000;
        ignoreAllDups = true;
        path = "${config.home.homeDirectory}/.zsh_history";
        ignorePatterns = [
          "rm *" "pkill *" "cp *" "history*" "exit" "ls" "cd" "pwd" "clear"
        ];
        share = true;
        extended = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
      };

      initExtra = ''
        ${lib.optionalString (config.sops.secrets ? KAGI_API_KEY) ''
          export KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
        ''}
        ${lib.optionalString (config.sops.secrets ? GITHUB_TOKEN) ''
          export GITHUB_TOKEN="$(cat ${config.sops.secrets.GITHUB_TOKEN.path})"
        ''}

        export SOPS_GPG_EXEC="$(which gpg)"
        export SOPS_GPG_ARGS="--pinentry-mode=loopback"

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

        export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
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

        function gclone() {
          [[ -z "$1" ]] && { echo "Usage: gclone <repo-url>"; return 1; }
          git clone "$1" && cd "$(basename "$1" .git)" || return 1
        }
        function gacp() {
          [[ -z "$1" ]] && { echo "Usage: gacp <commit-message>"; return 1; }
          git add . && git commit -m "$1" && git push || return 1
        }
        function gnew() {
          [[ -z "$1" ]] && { echo "Usage: gnew <branch-name>"; return 1; }
          git checkout -b "$1" && git push -u origin "$1" || return 1
        }
        function mkcd() {
          [[ -z "$1" ]] && { echo "Usage: mkcd <directory>"; return 1; }
          mkdir -p "$1" && cd "$1" || return 1
        }
        function cdf() {
          local file=$(fzf)
          [[ -z "$file" ]] && { echo "No file selected"; return 1; }
          cd "$(dirname "$file")" || return 1
        }
        function up() {
          local levels=''${1:-1}
          [[ ! "$levels" =~ ^[0-9]+$ ]] && { echo "Usage: up [number]"; return 1; }
          local path=""
          for ((i=1; i<=levels; i++)); do
            path="../$path"
          done
          cd "$path" || return 1
        }
        function bk() { cd "$OLDPWD" || return 1 }
        function cdl() {
          [[ -z "$1" ]] && { echo "Usage: cdl <directory>"; return 1; }
          cd "$1" && eza || return 1
        }
        function 1() { cd -1 2>/dev/null || { echo "Directory stack entry 1 not found"; return 1; } }
        function 2() { cd -2 2>/dev/null || { echo "Directory stack entry 2 not found"; return 1; } }
        function 3() { cd -3 2>/dev/null || { echo "Directory stack entry 3 not found"; return 1; } }
        function 4() { cd -4 2>/dev/null || { echo "Directory stack entry 4 not found"; return 1; } }
        function 5() { cd -5 2>/dev/null || { echo "Directory stack entry 5 not found"; return 1; } }
        function findcode() {
          print -l **/*.(js|ts|jsx|tsx|py|go|rs|c|cpp|h|hpp|java|php|rb|swift|kt)~*/(node_modules|target|build|dist|vendor)/*
        }
        function findconfig() {
          print -l **/*.(json|yaml|yml|toml|ini|conf|cfg|env)~*/(node_modules|target|build|dist|vendor)/*
        }
        function finddocs() {
          print -l **/*.(md|txt|rst|adoc|tex|pdf)~*/(node_modules|target|build|dist|vendor)/*
        }
        function findlarge() {
          print -l **/*(.Lm+10)
        }
        function findrecent() {
          print -l **/*(.mm-7)
        }
        function findold() {
          print -l **/*(.mm+30)
        }
        function extract() {
          [[ -z "$1" ]] && { echo "Usage: extract <file>"; return 1; }
          [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
          case "$1" in
            *.tar.bz2)   tar xjf "$1" || return 1 ;;
            *.tar.gz)    tar xzf "$1" || return 1 ;;
            *.bz2)       bunzip2 "$1" || return 1 ;;
            *.rar)       unrar x "$1" || return 1 ;;
            *.gz)        gunzip "$1" || return 1 ;;
            *.tar)       tar xf "$1" || return 1 ;;
            *.tbz2)      tar xjf "$1" || return 1 ;;
            *.tgz)       tar xzf "$1" || return 1 ;;
            *.zip)       unzip "$1" || return 1 ;;
            *.Z)         uncompress "$1" || return 1 ;;
            *.7z)        7z x "$1" || return 1 ;;
            *.xz)        unxz "$1" || return 1 ;;
            *.exe)       cabextract "$1" || return 1 ;;
            *)           echo "Error: '$1' cannot be extracted via extract()"; return 1 ;;
          esac
          echo "Successfully extracted '$1'"
        }
        function mktmp() {
          local tmp_dir=$(mktemp -d) || { echo "Failed to create temporary directory"; return 1; }
          echo "Created: $tmp_dir"
          cd "$tmp_dir" || return 1
        }
        function backup() {
          [[ -z "$1" ]] && { echo "Usage: backup <file>"; return 1; }
          [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
          local backup_name="$1.backup.$(date +%Y%m%d_%H%M%S)"
          cp "$1" "$backup_name" || return 1
          echo "Backup created: $backup_name"
        }
        function port() {
          [[ -z "$1" ]] && { echo "Usage: port <port-number>"; return 1; }
          [[ ! "$1" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
          lsof -ti:"$1" || { echo "No process found on port $1"; return 1; }
        }
        function killport() {
          [[ -z "$1" ]] && { echo "Usage: killport <port-number>"; return 1; }
          [[ ! "$1" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
          local pid=$(lsof -ti:"$1")
          [[ -z "$pid" ]] && { echo "No process found on port $1"; return 1; }
          kill -9 "$pid" || return 1
          echo "Killed process $pid on port $1"
        }
        function weather() {
          local location=''${1:-""}
          curl -s "wttr.in/$location" || { echo "Failed to fetch weather data"; return 1; }
        }
        function serve() {
          local port='${1:-8000}'
          [[ ! "$port" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
          command -v python >/dev/null 2>&1 || { echo "Python not found"; return 1; }
          echo "Starting server on port $port..."
          python -m http.server "$port" || return 1
        }
        function nix-dev() {
          if [[ -f shell.nix || -f .envrc ]]; then
            nix-shell || return 1
          else
            echo "No shell.nix or .envrc found in current directory"
            return 1
          fi
        }
        function flake-init() {
          [[ -z "$1" ]] && { echo "Usage: flake-init <template-name>"; return 1; }
          nix flake init --template "github:nix-community/templates#$1" || return 1
          echo "Initialized flake with template: $1"
        }

        ${
          let
            zsh_codex = pkgs.fetchFromGitHub {
              owner = "tom-doerr";
              repo = "zsh_codex";
              rev = "6ede649f1260abc5ffe91ef050d00549281dc461";
              hash = "sha256-m3m+ErBakBMrBsoiYgI8AdJZwXgcpz4C9hIM5Q+6lO4=";
            };
          in
          ''
            if [[ -f "${zsh_codex}/zsh_codex.plugin.zsh" ]]; then
              source "${zsh_codex}/zsh_codex.plugin.zsh"
              bindkey '^X' create_completion
            fi
          ''
        }
      '';
    };
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    EDITOR = "hx";
    DIRSTACKSIZE = "20";
    NH_FLAKE = "${config.home.homeDirectory}/.config/nix";
  };

  home.file = {
    ".p10k.zsh".source = ./lib/p10k.zsh;
  };

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "system-update";
      runtimeInputs = [ nh nix coreutils ];
      text = ''
        set -e
        FLAKE_PATH="${NH_FLAKE:-${config.home.homeDirectory}/.config/nix}"
        if [[ "${stdenv.hostPlatform.isDarwin}" == "1" ]]; then
          NH_CMD="nh darwin"
        else
          NH_CMD="nh os"
        fi
        UPDATE_INPUTS=0
        RUN_GC=0
        BUILD_ONLY=0
        for arg in "$@"; do
          case "$arg" in
            --full) UPDATE_INPUTS=1; RUN_GC=1 ;;
            --inputs) UPDATE_INPUTS=1 ;;
            --gc) RUN_GC=1 ;;
            --build-only) BUILD_ONLY=1 ;;
            --help)
              echo "Usage: system-update [--full|--inputs|--gc|--build-only|--help]"
              exit 0 ;;
          esac
        done
        if [[ $UPDATE_INPUTS -eq 1 ]]; then
          echo "Updating inputs…"
          nix flake update --flake "$FLAKE_PATH"
        fi
        if [[ $BUILD_ONLY -eq 1 ]]; then
          echo "Building…"
          $NH_CMD build "$FLAKE_PATH"
        else
          echo "Switching…"
          $NH_CMD switch "$FLAKE_PATH"
        fi
        if [[ $RUN_GC -eq 1 ]]; then
          echo "Cleaning…"
          nh clean all
        fi
        echo "Done."
      '';
    })
  ];
}
