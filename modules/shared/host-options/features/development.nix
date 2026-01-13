# Development Tools Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  development = {
    enable = mkEnableOption "development tools and environments" // {
      default = true;
      example = true;
    };

    rust = mkEnableOption "Rust development environment" // {
      default = true;
      example = true;
    };
    python = mkEnableOption "Python development environment" // {
      default = true;
      example = true;
    };
    go = mkEnableOption "Go development environment" // {
      default = false;
      example = true;
    };
    node = mkEnableOption "Node.js/TypeScript development" // {
      default = true;
      example = true;
    };
    lua = mkEnableOption "Lua development environment" // {
      default = false;
      example = true;
    };
    java = mkEnableOption "Java development environment" // {
      default = false;
      example = true;
    };
    nix = mkEnableOption "Nix development tools" // {
      example = true;
    };

    docker = mkEnableOption "Docker and containerization" // {
      example = true;
    };
    git = mkEnableOption "Git and version control tools" // {
      example = true;
    };
    neovim = mkEnableOption "Neovim text editor" // {
      default = false;
      example = true;
    };
  };
}
