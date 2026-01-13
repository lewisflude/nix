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
    };

    rust = mkEnableOption "Rust development environment" // {
      default = true;
    };
    python = mkEnableOption "Python development environment" // {
      default = true;
    };
    go = mkEnableOption "Go development environment" // {
      default = false;
    };
    node = mkEnableOption "Node.js/TypeScript development" // {
      default = true;
    };
    lua = mkEnableOption "Lua development environment" // {
      default = false;
    };
    java = mkEnableOption "Java development environment" // {
      default = false;
    };
    nix = mkEnableOption "Nix development tools";

    docker = mkEnableOption "Docker and containerization";
    git = mkEnableOption "Git and version control tools";
    neovim = mkEnableOption "Neovim text editor" // {
      default = false;
    };
  };
}
