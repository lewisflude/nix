# Shell Aliases Configuration
# Command aliases and shortcuts
{
  lib,
  hostSystem ? null,
  ...
}:
let
  isLinux = if hostSystem != null then lib.strings.hasSuffix "linux" hostSystem else false;
in
{
  programs.zsh.shellAliases = lib.mkMerge [
    {
      switch = if isLinux then "nh os switch" else "nh darwin switch";
      edit = "sudo -e";
      ls = "eza";
      l = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      ll = "eza -l --git --header";
      # cd is replaced by zoxide via --cmd cd (see initContent)
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
      nix-info = ", nix-info -m"; # Using comma for instant execution
      nix-size = "du -sh /nix/store";
      nix-update-lock = "nix flake update --flake ~/.config/nix";

      # Nix flake commands with automatic glob disabling
      # This prevents zsh from interpreting '#' as a glob pattern
      nix = "noglob nix";
      nix-build = "noglob nix build";
      nix-run = "noglob nix run";
      nix-develop = "noglob nix develop";
      nix-shell = "noglob nix-shell";

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
      zed = "zeditor";
    }
    (lib.mkIf isLinux {
      # Lock screen styling is handled in programs.swaylock.settings (Signal theme)
      lock = "swaylock -f";
    })
  ];
}
