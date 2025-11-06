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

    environment.systemPackages =
      with pkgs;
      [

        gnumake
        cmake
        pkg-config
        gcc
        binutils
      ]

      ++ optionals cfg.git [
        git
        gh
        git-lfs
        delta
      ]

      ++ optionals cfg.docker [
        docker
        docker-compose
        lazydocker
      ]

      ++ optionals cfg.languages.python [
        python3
        python3Packages.pip
        python3Packages.virtualenv
        poetry
        ruff
      ]

      ++ optionals cfg.languages.javascript [
        nodejs_24
        nodejs_24.pkgs.npm
        nodejs_24.pkgs.yarn
        nodejs_24.pkgs.pnpm
        nodejs_24.pkgs.typescript
        nodejs_24.pkgs.typescript-language-server
      ]

      ++ optionals cfg.languages.rust [
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer
      ]

      ++ optionals cfg.languages.go [
        go
        gopls
        golangci-lint
      ]

      ++ optionals cfg.editors.vscode [ vscode ]
      ++ optionals cfg.editors.neovim [ neovim ];

    virtualisation.docker.enable = mkIf cfg.docker true;

    programs.git = mkIf cfg.git {
      enable = true;
      lfs.enable = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    assertions = [
      {
        assertion = cfg.languages.rust -> cfg.git;
        message = "Rust development requires Git to be enabled";
      }
    ];
  };
}
