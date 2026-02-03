# Shell configuration - ALL config classes in ONE file
# Dendritic pattern: One feature = one file spanning all configurations
{ config, ... }:
let
  # Capture flake-parts config values (forces proper module registration)
  inherit (config) username;

  # ZSH plugin sources
  zshSources =
    { fetchgit }:
    {
      zsh-defer = {
        src = fetchgit {
          url = "https://github.com/romkatv/zsh-defer.git";
          rev = "53a26e287fbbe2dcebb3aa1801546c6de32416fa";
          sha256 = "sha256-MFlvAnPCknSgkW3RFA8pfxMZZS/JbyF3aMsJj9uHHVU=";
        };
      };
      zsh-auto-notify = {
        src = fetchgit {
          url = "https://github.com/MichaelAquilina/zsh-auto-notify.git";
          rev = "b51c934d88868e56c1d55d0a2a36d559f21cb2ee";
          sha256 = "sha256-s3TBAsXOpmiXMAQkbaS5de0t0hNC1EzUUb0ZG+p9keE=";
        };
      };
    };

  # Secret helpers for shell init
  secretAvailable =
    osConfig: name: osConfig ? sops && osConfig.sops ? secrets && osConfig.sops.secrets ? ${name};
  secretPath =
    osConfig: name: if secretAvailable osConfig name then osConfig.sops.secrets.${name}.path else "";
in
{
  # ═══════════════════════════════════════════════════════════════════
  # NixOS system-level shell configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.nixos.shell =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;
      users.users.${username}.shell = pkgs.zsh;
      environment.shells = [ pkgs.zsh ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Darwin system-level shell configuration
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.darwin.shell =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;
      environment.shells = [ pkgs.zsh ];
    };

  # ═══════════════════════════════════════════════════════════════════
  # Home-manager shell configuration (works on NixOS AND Darwin)
  # ═══════════════════════════════════════════════════════════════════
  flake.modules.homeManager.shell =
    {
      lib,
      pkgs,
      config,
      osConfig ? { },
      ...
    }:
    let
      sources = zshSources { inherit (pkgs) fetchgit; };
      isLinux = pkgs.stdenv.isLinux;
    in
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        dotDir = "${config.xdg.configHome}/zsh";
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
          "INTERACTIVE_COMMENTS"
          "LONG_LIST_JOBS"
          "NOTIFY"
          "HASH_LIST_ALL"
        ];

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

        dirHashes = {
          nix = "$HOME/.config/nix";
          dots = "$HOME/.config";
        };
        cdpath = [
          "~/.config"
          "~/projects"
        ];

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
            nix-info = "nix-info -m";
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
          (lib.mkIf isLinux { lock = "swaylock -f"; })
        ];

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

        localVariables = {
          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=240";
          AUTO_NOTIFY_THRESHOLD = 10;
          AUTO_NOTIFY_TITLE = "Command finished";
          AUTO_NOTIFY_BODY = "Completed in %elapsed seconds";
          ATUIN_NOBIND = "true";
        };

        sessionVariables = {
          DIRSTACKSIZE = "20";
          NH_SEARCH_CHANNEL = "nixpkgs-unstable";
          SYSTEMD_LESS = "FRSXMK --use-color";
        };

        envExtra = ''
          export WORDCHARS='*?_-.[]~=&;!'
          export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
          export SOPS_GPG_ARGS="--pinentry-mode=loopback"
          export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
        '';

        completionInit = ''
          autoload -Uz compinit
          mkdir -p ${config.xdg.cacheHome}/zsh
          fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
          local zcompdump="${config.xdg.cacheHome}/zsh/.zcompdump"
          if [[ ! -f "$zcompdump" ]] || [[ -n "$(find "$zcompdump" -mtime +1 2>/dev/null)" ]]; then
            compinit -d "$zcompdump"
          else
            compinit -C -d "$zcompdump"
          fi
          zstyle ':completion:*' use-cache yes
          zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh
        '';

        initContent = lib.mkMerge [
          ''
            ZSH_AUTOSUGGEST_STRATEGY=(history completion)
            AUTO_NOTIFY_IGNORE=("man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync" "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff")
          ''
          (lib.mkBefore ''
            # Skip ZSH config in Cursor Agent shells for clean command execution
            if [[ "$PAGER" == "head -n 10000 | cat" || "$COMPOSER_NO_INTERACTION" == "1" ]]; then
              return
            fi

            # Suppress direnv output during initialization
            export DIRENV_LOG_FORMAT=""
            export DIRENV_WARN_TIMEOUT=0

            # Load zsh-defer early (required for all deferred loading)
            source ${sources.zsh-defer.src}/zsh-defer.plugin.zsh
          '')
          (lib.mkAfter ''
            # ════════════════════════════════════════════════════════════════
            # Cached Initialization (Performance Optimization)
            # ════════════════════════════════════════════════════════════════
            [[ -f ~/.config/zsh/zoxide-init.zsh ]] && source ~/.config/zsh/zoxide-init.zsh
            [[ -f ~/.config/zsh/fzf-init.zsh ]] && source ~/.config/zsh/fzf-init.zsh
            [[ -f ~/.config/zsh/direnv-init.zsh ]] && source ~/.config/zsh/direnv-init.zsh
            [[ -f ~/.config/zsh/atuin-init.zsh ]] && zsh-defer source ~/.config/zsh/atuin-init.zsh

            # ════════════════════════════════════════════════════════════════
            # Dynamic Variables & GPG Configuration
            # ════════════════════════════════════════════════════════════════
            export GPG_TTY=$TTY
            zsh-defer ${pkgs.gnupg}/bin/gpg-connect-agent --quiet updatestartuptty /bye > /dev/null 2>&1 || true

            # SSH_AUTH_SOCK: Use systemd user service socket
            if [[ -o interactive ]]; then
              if [[ -S "''${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh" ]]; then
                export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR:-/run/user/$UID}/gnupg/S.gpg-agent.ssh"
              else
                if [[ -z "$SSH_AUTH_SOCK" ]]; then
                  export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
                fi
              fi
            fi

            # ════════════════════════════════════════════════════════════════
            # Lazy Secret Loading
            # ════════════════════════════════════════════════════════════════
            ${lib.optionalString (secretAvailable osConfig "KAGI_API_KEY") ''
              function kagi() {
                if [[ -z "$KAGI_API_KEY" ]]; then
                  local secret_path="${lib.escapeShellArg (secretPath osConfig "KAGI_API_KEY")}"
                  [[ -r "$secret_path" ]] && export KAGI_API_KEY="$(cat "$secret_path")"
                fi
                command kagi "$@"
              }
            ''}

            ${lib.optionalString (secretAvailable osConfig "GITHUB_TOKEN") ''
              function gh() {
                if [[ -z "$GITHUB_TOKEN" ]]; then
                  local secret_path="${lib.escapeShellArg (secretPath osConfig "GITHUB_TOKEN")}"
                  [[ -r "$secret_path" ]] && export GITHUB_TOKEN="$(cat "$secret_path")"
                fi
                command gh "$@"
              }
            ''}

            # ════════════════════════════════════════════════════════════════
            # Zstyle Configuration (Completion Styling)
            # ════════════════════════════════════════════════════════════════
            zstyle ':completion:*' completer _complete _match _approximate
            zstyle ':completion:*:match:*' original only
            zstyle ':completion:*:approximate:*' max-errors 1 numeric
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
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

            # ════════════════════════════════════════════════════════════════
            # Shell Options & Correction
            # ════════════════════════════════════════════════════════════════
            unsetopt FLOW_CONTROL

            if [[ ! -o interactive || ! -t 1 || "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "cursor" ]]; then
              unsetopt CORRECT CORRECT_ALL
            else
              setopt CORRECT
              unsetopt CORRECT_ALL
            fi

            # ════════════════════════════════════════════════════════════════
            # Custom Functions (Load Immediately)
            # ════════════════════════════════════════════════════════════════
            [[ -f "${config.home.homeDirectory}/.config/nix/lib/zsh/functions.zsh" ]] && source "${config.home.homeDirectory}/.config/nix/lib/zsh/functions.zsh"
            [[ -f "${config.home.homeDirectory}/.config/nix/lib/zsh/p10k-diagnostics.zsh" ]] && source "${config.home.homeDirectory}/.config/nix/lib/zsh/p10k-diagnostics.zsh"

            # ════════════════════════════════════════════════════════════════
            # Terminfo-Based Keybindings
            # ════════════════════════════════════════════════════════════════
            typeset -g -A key
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
            key[Control-Left]="''${terminfo[kLFT5]}"
            key[Control-Right]="''${terminfo[kRIT5]}"
            key[Control-Delete]="''${terminfo[kDC5]}"

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
            [[ -n "''${key[Control-Left]}"  ]] && bindkey -- "''${key[Control-Left]}"  backward-word
            [[ -n "''${key[Control-Right]}" ]] && bindkey -- "''${key[Control-Right]}" forward-word
            bindkey '^H' backward-kill-word
            [[ -n "''${key[Control-Delete]}" ]] && bindkey -- "''${key[Control-Delete]}" kill-word

            # Application Mode (Terminal State Management)
            if (( ''${+terminfo[smkx]} && ''${+terminfo[rmkx]} )); then
              autoload -Uz add-zle-hook-widget
              function zle_application_mode_start { echoti smkx }
              function zle_application_mode_stop { echoti rmkx }
              add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
              add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
            fi

            # Ghostty Multiline Support
            function _ghostty_insert_newline() { LBUFFER+=$'\n' }
            zle -N ghostty-insert-newline _ghostty_insert_newline
            bindkey -M emacs $'\e[99997u' ghostty-insert-newline
            bindkey -M viins $'\e[99997u' ghostty-insert-newline
            bindkey -M emacs $'\e\r'     ghostty-insert-newline
            bindkey -M viins $'\e\r'     ghostty-insert-newline

            # ════════════════════════════════════════════════════════════════
            # Deferred Plugin Loading
            # ════════════════════════════════════════════════════════════════
            zsh-defer source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            zsh-defer source ${sources.zsh-auto-notify.src}/auto-notify.plugin.zsh
            zsh-defer source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
            typeset -gA ZSH_HIGHLIGHT_STYLES
            zsh-defer source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

            # Plugin-Specific Keybindings (deferred)
            if [[ -o interactive ]]; then
              zsh-defer -c 'bindkey "^r" _atuin_search_widget'
              zsh-defer -c 'bindkey "^P" history-substring-search-up'
              zsh-defer -c 'bindkey "^N" history-substring-search-down'
            fi
          '')
        ];
      };

      home.sessionVariables = {
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        EDITOR = "hx";
        COLORTERM = "truecolor";
        CLICOLOR = "1";
        DIRENV_LOG_FORMAT = "";
        DIRENV_WARN_TIMEOUT = "20s";
        DIRENV_TIMEOUT = "5s";
      };

      home.packages = [ pkgs.zoxide ];

      # Pre-generated init scripts
      home.file.".config/zsh/zoxide-init.zsh".source = pkgs.runCommand "zoxide-init" { } ''
        ${pkgs.zoxide}/bin/zoxide init zsh --cmd cd > $out
      '';
      home.file.".config/zsh/fzf-init.zsh".source = pkgs.runCommand "fzf-init" { } ''
        ${pkgs.fzf}/bin/fzf --zsh > $out 2>/dev/null || echo "# fzf init" > $out
      '';
      home.file.".config/zsh/direnv-init.zsh".source = pkgs.runCommand "direnv-init" { } ''
        ${pkgs.direnv}/bin/direnv hook zsh > $out
      '';
      home.file.".config/zsh/atuin-init.zsh".source = pkgs.runCommand "atuin-init" { } ''
        export HOME="$TMPDIR"; mkdir -p "$HOME/.config/atuin"
        ${pkgs.atuin}/bin/atuin init zsh --disable-up-arrow > $out 2>&1 || echo "export ATUIN_NOBIND=true" > $out
      '';

      # Direnv layout file for Zellij integration
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
    };
}
