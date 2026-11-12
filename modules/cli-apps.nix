# Simple CLI applications - Tools with minimal configuration
# Complex CLI apps with extensive configuration are in separate modules
_: {
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
      # Colours (gui.theme) are owned by signal-nix via autoEnable; only
      # behaviour (paging) is set here.
      programs.lazygit = {
        enable = true;
        settings = {
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
        pkgs.rsync
        pkgs.fd
        pkgs.ouch
        pkgs.sd
        pkgs.hyperfine
        pkgs.just
        pkgs.trash-cli
        pkgs.dust
        pkgs.procs
        pkgs.gping
        pkgs._7zz-rar
        pkgs.pigz
        pkgs.git-extras

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

        # Binary caching
        # Builds from source on aarch64-darwin when the pinned nixpkgs rev
        # lacks a cache hit; its Haskell test suite then aborts on the same
        # libffi trampoline assertion as pgcli below, so skip checks.
        (pkgs.cachix.overrideAttrs (_: {
          doCheck = false;
        }))
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.libnotify
        pkgs.lsof
      ];
    };
}
