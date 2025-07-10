{
  pkgs,
  config,
  system,
  lib,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlight = "fg=#ff00ff,bg=cyan,bold,underline";
    };
    syntaxHighlighting.enable = true;
    
    # Additional useful plugins
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
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
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
    
    # Extended completions with lazy loading
    completionInit = ''
      autoload -Uz compinit
      # Check if we need to regenerate completions daily
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
      
      # Load additional completions
      fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
      
      # Enable completion caching
      zstyle ':completion:*' use-cache yes
      zstyle ':completion:*' cache-path ~/.zsh/cache
      
      # Lazy load tool-specific completions
      _lazy_load_docker_completion() {
        if command -v docker &> /dev/null && [[ ! -f ~/.zsh/cache/docker_completion_loaded ]]; then
          source <(docker completion zsh) 2>/dev/null || true
          touch ~/.zsh/cache/docker_completion_loaded
        fi
      }
      
      _lazy_load_kubectl_completion() {
        if command -v kubectl &> /dev/null && [[ ! -f ~/.zsh/cache/kubectl_completion_loaded ]]; then
          source <(kubectl completion zsh) 2>/dev/null || true
          touch ~/.zsh/cache/kubectl_completion_loaded
        fi
      }
      
      _lazy_load_npm_completion() {
        if command -v npm &> /dev/null && [[ ! -f ~/.zsh/cache/npm_completion_loaded ]]; then
          source <(npm completion) 2>/dev/null || true
          touch ~/.zsh/cache/npm_completion_loaded
        fi
      }
      
      # Set up lazy loading triggers
      docker() { _lazy_load_docker_completion; unfunction docker; docker "$@"; }
      kubectl() { _lazy_load_kubectl_completion; unfunction kubectl; kubectl "$@"; }
      npm() { _lazy_load_npm_completion; unfunction npm; npm "$@"; }
      
      # Create cache directory
      mkdir -p ~/.zsh/cache
    '';
    shellAliases = {
      # System management
      switch = platformLib.systemRebuildCommand;
      update = "system-update";
      edit = "sudo -e";
      
      # File operations
      ls = "eza";
      l = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      ll = "eza -l --git --header";
      lsd = "eza"; # Fallback alias
      cd = "z";
      grep = "rg";
      find = "fd";
      cat = "bat";
      top = "htop";
      
      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      d = "dirs -v";           # Show directory stack with numbers
      po = "popd";             # Pop directory from stack
      pu = "pushd";            # Push directory to stack
      
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
      ports = "netstat -tulanp";
      myip = "curl -s ifconfig.me";
      
      # Nix utilities
      nix-search = "nh search";
      nix-info = "nix-shell -p nix-info --run 'nix-info -m'";
      nix-size = "du -sh /nix/store";
      
      # NH shortcuts
      nh-os = "nh os";
      nh-home = "nh home";
      nh-darwin = "nh darwin";
      nh-clean = "nh clean all";
      
      # Development environments
      dev = "nix develop ~/.config/nix#shell-selector";
      
      # Abbreviation helpers
      abbr-list = "abbr list";
      abbr-add = "abbr add";
      abbr-erase = "abbr erase";
      
      # Globbing helpers
      lsh = "eza -la .*";              # List hidden files
      lsz = "eza -la **/*.{zip,tar,gz,bz2,xz,7z}";  # List archives recursively
      lscode = "eza -la **/*.{js,ts,jsx,tsx,py,go,rs,c,cpp,h,hpp}";  # List code files
      lsconfig = "eza -la **/*.{json,yaml,yml,toml,ini,conf,cfg}";
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
      
      # Advanced history options
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
    };
    initContent = ''
      # Load secrets securely
      ${lib.optionalString (config.sops.secrets ? KAGI_API_KEY) ''
        export KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
      ''}
      
      if [[ -f /run/secrets/GITHUB_PERSONAL_ACCESS_TOKEN ]]; then
        export GITHUB_TOKEN="$(cat /run/secrets/GITHUB_PERSONAL_ACCESS_TOKEN)"
      fi
      
      export SOPS_GPG_EXEC="$(which gpg)"
      export SOPS_GPG_ARGS="--pinentry-mode=loopback"
      
      # Initialize core tools (critical for shell functionality)
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      eval "$(direnv hook zsh)"
      eval "$(${pkgs.atuin}/bin/atuin init zsh)"
      
      # Theme setup (critical for prompt)
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      
      # Defer non-critical initializations
      zsh-defer -c 'export YSU_MESSAGE_POSITION="after"'
      zsh-defer -c 'export YSU_HARDCORE=1'
      
      # Configure zsh-auto-notify
      export AUTO_NOTIFY_THRESHOLD=10
      export AUTO_NOTIFY_TITLE="Command finished"
      export AUTO_NOTIFY_BODY="Completed in %elapsed seconds"
      export AUTO_NOTIFY_IGNORE=(
        "man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync"
        "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff"
      )
      
      # Better word selection for navigation
      export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
      
      # Atuin configuration
      export ATUIN_NOBIND="true"
      zsh-defer -c 'bindkey "^r" _atuin_search_widget'
      
      # GPG and SSH setup (deferred)
      zsh-defer -c 'gpgconf --launch gpg-agent 2>/dev/null'
      zsh-defer -c 'if [[ -f ~/.ssh/id_ecdsa_sk_github ]]; then
        ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf ~/.ssh/id_ecdsa_sk_github.pub 2>/dev/null | awk '"'"'{print $2}'"'"' 2>/dev/null)" || ssh-add ~/.ssh/id_ecdsa_sk_github 2>/dev/null
      fi'
      
      # Key bindings
      bindkey '^R' history-incremental-search-backward
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^H' backward-kill-word
      bindkey '^[[3;5~' kill-word
      
      # History substring search (requires zsh-history-substring-search plugin)
      bindkey '^[[A' history-substring-search-up    # Up arrow
      bindkey '^[[B' history-substring-search-down  # Down arrow
      bindkey '^P' history-substring-search-up      # Ctrl+P
      bindkey '^N' history-substring-search-down    # Ctrl+N
      
      # FZF configuration (deferred)
      zsh-defer -c 'export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"'
      zsh-defer -c 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"'
      zsh-defer -c 'export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"'
      
      # FZF integration (deferred)
      zsh-defer source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      zsh-defer source ${pkgs.fzf}/share/fzf/completion.zsh
      
      # Advanced completion matching
      zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|[._-]=* r:|=*' \
        'l:|=* r:|=*'
      
      # Completion styling and behavior
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' list-colors '${"\${(s.:.)LS_COLORS}"}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose true
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
      zstyle ':completion:*:corrections' format '%F{green}%d (errors: %e)%f'
      
      # Process completion styling
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:kill:*' force-list always
      
      # Directory completion
      zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:cd:*' ignore-parents parent pwd
      
      # File completion
      zstyle ':completion:*' file-patterns '%p:globbed-files *(-/):directories' '*:all-files'
      
      # Performance optimizations
      setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END
      
      # Advanced history options
      setopt HIST_VERIFY              # Show command before executing from history
      setopt HIST_REDUCE_BLANKS       # Remove extra blanks from history
      setopt HIST_IGNORE_SPACE        # Don't record commands starting with space
      setopt HIST_NO_FUNCTIONS        # Don't record function definitions
      setopt HIST_EXPIRE_DUPS_FIRST   # Remove duplicates first when trimming history
      setopt HIST_FIND_NO_DUPS        # Don't show duplicates in search
      setopt HIST_SAVE_NO_DUPS        # Don't save duplicates to history file
      setopt HIST_BEEP                # Beep when accessing non-existent history
      setopt BANG_HIST                # Treat '!' specially for history expansion
      
      # Advanced navigation options
      setopt AUTO_PUSHD               # Make cd push old directory onto directory stack
      setopt PUSHD_IGNORE_DUPS        # Don't push duplicate directories onto stack
      setopt PUSHD_SILENT             # Don't print directory stack after pushd/popd
      setopt PUSHD_TO_HOME            # pushd with no arguments goes to home
      setopt CDABLE_VARS              # Allow cd to variables (cd $HOME works as cd ~)
      setopt AUTO_CD                  # Auto cd to directory if command is a directory name
      setopt MULTIOS                  # Allow multiple redirections
      
      # Advanced globbing options
      setopt EXTENDED_GLOB            # Enable extended globbing patterns
      setopt GLOB_DOTS                # Include dotfiles in glob patterns
      setopt GLOB_STAR_SHORT          # ** for recursive globbing
      setopt NUMERIC_GLOB_SORT        # Sort numeric filenames numerically
      setopt MARK_DIRS                # Add trailing slash to directory names in glob
      setopt NOMATCH                  # Print error if glob pattern has no matches
      setopt CASE_GLOB                # Case-sensitive globbing (default, but explicit)
      setopt BAD_PATTERN              # Print error for malformed glob patterns
      
      # Quality of life improvements
      setopt CORRECT                  # Correct misspelled commands
      setopt CORRECT_ALL              # Correct misspelled arguments too
      setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
      setopt LONG_LIST_JOBS           # Show more info in job control
      setopt NOTIFY                   # Report status of background jobs immediately
      setopt HASH_LIST_ALL            # Hash entire command path on first execution
      setopt COMPLETEINWORD           # Complete from both ends of word
      setopt ALWAYS_TO_END            # Move cursor to end after completion
      setopt AUTO_MENU                # Show completion menu on successive tab press
      setopt AUTO_LIST                # Automatically list choices on ambiguous completion
      setopt AUTO_PARAM_SLASH         # Add slash after completing directory names
      setopt FLOW_CONTROL             # Disable start/stop characters in shell editor
      
      # Precompile for faster startup (deferred)
      zsh-defer -c 'if [[ ~/.zshrc -nt ~/.zshrc.zwc ]]; then
        zcompile ~/.zshrc
      fi'
      
      # Git helpers
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
      
      # Directory navigation helpers
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
      
      # Directory stack shortcuts
      function 1() { cd -1 2>/dev/null || { echo "Directory stack entry 1 not found"; return 1; } }
      function 2() { cd -2 2>/dev/null || { echo "Directory stack entry 2 not found"; return 1; } }
      function 3() { cd -3 2>/dev/null || { echo "Directory stack entry 3 not found"; return 1; } }
      function 4() { cd -4 2>/dev/null || { echo "Directory stack entry 4 not found"; return 1; } }
      function 5() { cd -5 2>/dev/null || { echo "Directory stack entry 5 not found"; return 1; } }
      
      # Advanced globbing functions
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
        print -l **/*(.Lm+10) # Files larger than 10MB
      }
      function findrecent() { 
        print -l **/*(.mm-7) # Files modified in last 7 days
      }
      function findold() { 
        print -l **/*(.mm+30) # Files older than 30 days
      }
      
      # Quality of life utility functions
      function extract() {
        [[ -z "$1" ]] && { echo "Usage: extract <file>"; return 1; }
        [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
        
        case "$1" in
          *.tar.bz2)   tar xjf "$1" || return 1    ;;
          *.tar.gz)    tar xzf "$1" || return 1    ;;
          *.bz2)       bunzip2 "$1" || return 1    ;;
          *.rar)       unrar x "$1" || return 1    ;;
          *.gz)        gunzip "$1" || return 1     ;;
          *.tar)       tar xf "$1" || return 1     ;;
          *.tbz2)      tar xjf "$1" || return 1    ;;
          *.tgz)       tar xzf "$1" || return 1    ;;
          *.zip)       unzip "$1" || return 1      ;;
          *.Z)         uncompress "$1" || return 1 ;;
          *.7z)        7z x "$1" || return 1       ;;
          *.xz)        unxz "$1" || return 1       ;;
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
        local port=''${1:-8000}
        [[ ! "$port" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
        command -v python >/dev/null 2>&1 || { echo "Python not found"; return 1; }
        echo "Starting server on port $port..."
        python -m http.server "$port" || return 1
      }
      
      # Nix helpers
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
      
      # AI coding assistant
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

  # Environment variables managed by home-manager
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    EDITOR = "hx";
    
    # Directory stack configuration
    DIRSTACKSIZE = "20";  # Maximum number of directories in stack
    
    # NH flake configuration
    NH_FLAKE = "${config.home.homeDirectory}/.config/nix";
  };

  home.file = {
    ".p10k.zsh".source = ./lib/p10k.zsh;
  };

  # System update script using nh
  home.packages = with pkgs; [
    (writeShellScriptBin "system-update" ''
      #!/bin/sh
      set -e
      
      # Use NH_FLAKE environment variable if set, fallback to default
      FLAKE_PATH="''${NH_FLAKE:-${config.home.homeDirectory}/.config/nix}"
      
      # Detect system
      if [[ "$OSTYPE" == "darwin"* ]]; then
        HOST_NAME="Lewiss-MacBook-Pro"
        NH_CMD="nh darwin"
      else
        HOST_NAME="jupiter"
        NH_CMD="nh os"
      fi
      
      # Parse options
      UPDATE_INPUTS=0
      RUN_GC=0
      BUILD_ONLY=0
      
      for arg in "$@"; do
        case $arg in
          --full) UPDATE_INPUTS=1; RUN_GC=1 ;;
          --inputs) UPDATE_INPUTS=1 ;;
          --gc) RUN_GC=1 ;;
          --build-only) BUILD_ONLY=1 ;;
          --help)
            echo "Usage: system-update [--full|--inputs|--gc|--build-only|--help]"
            echo "  --full        Update inputs and run garbage collection"
            echo "  --inputs      Update flake inputs"
            echo "  --gc          Run garbage collection"
            echo "  --build-only  Build configuration without switching"
            exit 0 ;;
        esac
      done
      
      # Execute operations
      [ $UPDATE_INPUTS -eq 1 ] && { echo "🔄 Updating inputs..."; nix flake update --flake "$FLAKE_PATH"; }
      
      if [ $BUILD_ONLY -eq 1 ]; then
        echo "⚙️ Building configuration..."
        $NH_CMD build "$FLAKE_PATH"
      else
        echo "⚙️ Switching configuration..."
        $NH_CMD switch "$FLAKE_PATH"
      fi
      
      [ $RUN_GC -eq 1 ] && { echo "🧹 Cleaning up..."; nh clean all; }
      
      echo "✨ Complete!"
    '')
  ];
}
