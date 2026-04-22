# JavaScript toolchain — Node.js + pnpm for ad-hoc use outside per-project devShells.
# Do NOT enable corepack here: `corepack enable` fails on NixOS/nix-darwin with
# EROFS because it tries to write symlinks inside the read-only Nix store.
# Use `pkgs.pnpm` directly; pin a project-specific version via devenv when needed.
_: {
  flake.modules.homeManager.javascript =
    { config, pkgs, ... }:
    {
      home.packages = [
        pkgs.nodejs_22
        pkgs.pnpm
      ];

      # Redirect `npm install -g` away from the read-only Nix store.
      home.sessionVariables = {
        NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      };

      home.sessionPath = [
        "${config.home.homeDirectory}/.npm-global/bin"
      ];
    };
}
