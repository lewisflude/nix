# Simple CLI applications - Tools with minimal configuration
# Complex CLI apps with extensive configuration are in separate modules
{ config, ... }:
{
  flake.modules.homeManager.cliApps =
    { lib, pkgs, ... }:
    {
      # JSON processor
      programs.jq.enable = true;

      # Cat replacement with syntax highlighting
      programs.bat.enable = true;

      # Modern ls replacement
      programs.eza = {
        enable = true;
        enableZshIntegration = true;
        colors = "auto";
        git = true;
        icons = "auto";
        extraOptions = [
          "--header"
          "--group-directories-first"
        ];
      };

      # Ripgrep configuration
      programs.ripgrep = {
        enable = true;
        arguments = [
          "--max-columns-preview"
          "--colors=line:style:bold"
        ];
      };

      # TLDR pages - simplified man pages
      programs.tealdeer = {
        enable = true;
        enableAutoUpdates = true;
        settings = {
          display = {
            compact = false;
            use_pager = true;
          };
          updates = {
            auto_update = true;
          };
        };
      };

      # Nix package search and comma command
      programs.nix-index = {
        enable = true;
        enableZshIntegration = true;
      };

      # AWS CLI
      programs.awscli.enable = true;

      # System monitoring
      programs.htop.enable = true;
      programs.btop.enable = true;

      # Core utilities and tooling
      home.packages = [
        # Essentials
        pkgs.curl
        pkgs.tree
        pkgs.ouch # Archive extraction

        # Nix Power Tools
        pkgs.nix-output-monitor
        pkgs.nix-tree
        pkgs.comma

        # Modern Nix Dev Flow
        pkgs.nix-init
        pkgs.nurl
        pkgs.nix-diff

        # Workflow
        pkgs.cocogitto
        pkgs.yaml-language-server
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.libnotify ];
    };
}
