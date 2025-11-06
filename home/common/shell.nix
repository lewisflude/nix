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
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;

  sources = import ./_sources/generated.nix {
    inherit (pkgs) fetchgit;
  };

  palette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then

      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then

      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else

      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";
  secretAvailable = name: lib.hasAttrByPath [ "sops" "secrets" name "path" ] systemConfig;
  secretPath = name: lib.attrByPath [ "sops" "secrets" name "path" ] "" systemConfig;
  secretExportSnippet =
    name: var:
    let
      path = secretPath name;
    in
    lib.optionalString (secretAvailable name) ''
      if [ -r ${lib.escapeShellArg path} ]; then
        export ${var}="$(cat ${lib.escapeShellArg path})"
      fi
    '';
in
{
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
        if pkgs ? fd then
          "${lib.getExe pkgs.fd} --hidden --strip-cwd-prefix --exclude .git"
        else if pkgs ? ripgrep then
          "${lib.getExe pkgs.ripgrep} --files --hidden --follow --glob '!.git'"
        else
          null
      );
      fileWidgetCommand = lib.mkDefault (
        if pkgs ? fd then
          "${lib.getExe pkgs.fd} --type f --hidden --strip-cwd-prefix --exclude .git"
        else
          null
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
      flags = [ "--disable-up-arrow" ];
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
          name = "zsh-bd";
          inherit (sources.zsh-bd) src;
          file = "bd.zsh";
        }
      ];
      completionInit = ''
        setopt EXTENDED_GLOB
        autoload -Uz compinit


        mkdir -p ${config.xdg.cacheHome}/zsh



        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)



        setopt EXTENDEDGLOB
        local zcompdump="${config.xdg.cacheHome}/zsh/.zcompdump"
        if [[ -n $zcompdump(

          compinit -C -d "$zcompdump"
        else

          compinit -i -d "$zcompdump"
        fi
        unsetopt EXTENDEDGLOB


        zstyle ':completion:*' use-cache yes
        zstyle ':completion:*' cache-path ${config.xdg.cacheHome}/zsh




      '';

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
      shellAliases = lib.mkMerge [
        {
          switch = platformLib.systemRebuildCommand { hostName = host.hostname; };
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

      initContent = lib.mkMerge [
        (lib.mkBefore ''



          export DIRENV_LOG_FORMAT=""
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        '')

        (lib.mkAfter ''
          ${secretExportSnippet "KAGI_API_KEY" "KAGI_API_KEY"}
          ${secretExportSnippet "GITHUB_TOKEN" "GITHUB_TOKEN"}
          export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"

          typeset -ga ZSH_AUTOSUGGEST_STRATEGY
          ZSH_AUTOSUGGEST_STRATEGY=(history completion)
          export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${palette.mauve.hex},bg=${palette.surface1.hex},bold,underline"
          export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
          export SOPS_GPG_ARGS="--pinentry-mode=loopback"
          export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"


          export NH_CLEAN_ARGS="''${NH_CLEAN_ARGS:---keep-since 4d --keep 3}"
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
          zsh-defer -c 'export YSU_MESSAGE_POSITION="after"'
          zsh-defer -c 'export YSU_HARDCORE=1'

          zsh-defer -c 'export AUTO_NOTIFY_THRESHOLD=10'
          zsh-defer -c 'export AUTO_NOTIFY_TITLE="Command finished"'
          zsh-defer -c 'export AUTO_NOTIFY_BODY="Completed in %elapsed seconds"'
          zsh-defer -c 'export AUTO_NOTIFY_IGNORE=(
            "man" "less" "more" "vim" "nano" "htop" "top" "ssh" "scp" "rsync"
            "watch" "tail" "sleep" "ping" "curl" "wget" "git log" "git diff"
          )'
          export WORDCHARS='*?_-.[]~=&;!
          export ATUIN_NOBIND="true"
          zsh-defer -c 'bindkey "^r" _atuin_search_widget'
          bindkey '^[[1;5C' forward-word
          bindkey '^[[1;5D' backward-word
          bindkey '^H' backward-kill-word
          bindkey '^[[3;5~' kill-word


          bindkey '^P' history-substring-search-up
          bindkey '^N' history-substring-search-down
          function _ghostty_insert_newline() { LBUFFER+=$'\n' }
          zle -N ghostty-insert-newline _ghostty_insert_newline
          bindkey -M emacs $'\e[99997u' ghostty-insert-newline
          bindkey -M viins $'\e[99997u' ghostty-insert-newline
          bindkey -M emacs $'\e\r'     ghostty-insert-newline
          bindkey -M viins $'\e\r'     ghostty-insert-newline

          zstyle ':completion:*' completer _complete _match _approximate
          zstyle ':completion:*:match:*' original only
          zstyle ':completion:*:approximate:*' max-errors 1 numeric

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
          zstyle ':completion:*:*:kill:*:processes' list-colors '=(
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



          if [[ -f "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh" ]]; then
            source "${config.home.homeDirectory}/.config/nix/home/common/lib/zsh/functions.zsh"
          fi

          source ${sources.zsh_codex.src}/zsh_codex.plugin.zsh
          bindkey '^X' create_completion

          eval "$(zoxide init zsh)"
        '')
      ];
    };
  };
  home = {

    sessionVariables = {
      EDITOR = "hx";
      NH_FLAKE = "${config.home.homeDirectory}/.config/nix";

      DIRENV_LOG_FORMAT = "";
    };
    file = {
      ".p10k.zsh".source = ./lib/p10k.zsh;
    };
    packages = with pkgs; [
      zoxide
    ];
  };
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
