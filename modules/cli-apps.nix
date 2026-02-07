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

      # Nix package search and comma command
      programs.nix-index = {
        enable = true;
        enableZshIntegration = true;
      };

      # AWS CLI
      programs.awscli.enable = true;

      # System monitoring
      programs.btop.enable = true;

      # Git TUI - lazygit
      programs.lazygit = {
        enable = true;
        settings = {
          gui.theme = {
            lightTheme = false;
            activeBorderColor = [ "green" "bold" ];
            inactiveBorderColor = [ "white" ];
          };
          git.paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          };
        };
      };

      # Fast Python package manager
      programs.uv = {
        enable = true;
        settings = {
          pip.index-url = "https://pypi.org/simple";
        };
      };

      # Core utilities and tooling
      home.packages = [
        # Essentials
        pkgs.curl
        pkgs.tree
        pkgs.ouch # Archive extraction
        pkgs.sd # Modern sed alternative
        pkgs.hyperfine # Benchmarking tool
        pkgs.just # Modern make alternative

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

        # Development environments and caching
        pkgs.devenv
        pkgs.cachix
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.libnotify ];
    };
}
