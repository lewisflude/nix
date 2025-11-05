# Example: Development Feature Module
# Demonstrates a more complex feature with language sub-features.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.development;
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.lists) optionals;
in
{
  options.features.development = {
    enable = mkEnableOption "development tools and environments";

    # Core development tools (always enabled with feature)
    git = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Git and related tools";
    };

    docker = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker for containerization";
    };

    # Language-specific sub-features
    languages = {
      python = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Python development environment";
      };

      javascript = mkOption {
        type = types.bool;
        default = true;
        description = "Enable JavaScript/Node.js development";
      };

      rust = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Rust development environment";
      };

      go = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Go development environment";
      };
    };

    # IDE/Editor options
    editors = {
      vscode = mkOption {
        type = types.bool;
        default = false;
        description = "Install VS Code";
      };

      neovim = mkOption {
        type = types.bool;
        default = false;
        description = "Install Neovim with development plugins";
      };
    };
  };

  config = mkIf cfg.enable {
    # Core development packages
    environment.systemPackages =
      with pkgs;
      [
        # Always include these
        gnumake
        cmake
        pkg-config
        gcc
        binutils
      ]
      # Git and tools
      ++ optionals cfg.git [
        git
        gh
        git-lfs
        delta
      ]
      # Docker
      ++ optionals cfg.docker [
        docker
        docker-compose
        lazydocker
      ]
      # Python
      ++ optionals cfg.languages.python [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        poetry
        ruff
      ]
      # JavaScript/Node.js
      ++ optionals cfg.languages.javascript [
        nodejs_24
        nodejs_24.pkgs.npm
        nodejs_24.pkgs.yarn
        nodejs_24.pkgs.pnpm
        nodejs_24.pkgs.typescript
        nodejs_24.pkgs.typescript-language-server
      ]
      # Rust
      ++ optionals cfg.languages.rust [
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer
      ]
      # Go
      ++ optionals cfg.languages.go [
        go
        gopls
        golangci-lint
      ]
      # Editors
      ++ optionals cfg.editors.vscode [ vscode ]
      ++ optionals cfg.editors.neovim [ neovim ];

    # Enable Docker service if Docker is enabled
    virtualisation.docker.enable = mkIf cfg.docker true;

    # Git configuration
    programs.git = mkIf cfg.git {
      enable = true;
      lfs.enable = true;
    };

    # Development-friendly shell configuration
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.languages.rust -> cfg.git;
        message = "Rust development requires Git to be enabled";
      }
    ];
  };
}
