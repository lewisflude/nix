# Per-system formatting with treefmt-nix
# Dendritic pattern: Provides nix fmt and checks.treefmt for each system
# Replaces standalone treefmt.toml and modules/per-system/formatters.nix
{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        settings.global.excludes = [
          "secrets/*.yaml"
          "flake.lock"
        ];

        # Nix formatters
        programs.nixfmt.enable = true;
        programs.deadnix = {
          enable = true;
          no-lambda-arg = true;
        };

        # Shell formatter
        programs.shfmt = {
          enable = true;
          indent_size = 2;
        };

        # Statix linter/fixer with file excludes (migrated from statix.toml)
        programs.statix = {
          enable = true;
          includes = [ "*.nix" ];
          excludes = [
            "**/systems.nix"
            "**/palette.nix"
            "**/wlsunset.nix"
            "**/polkit-gnome.nix"
            "**/gemini-cli.nix"
            "**/video-conferencing.nix"
            "**/keyboard.nix"
          ];
        };

        # Prettier for YAML and Markdown
        settings.formatter.prettier-yaml = {
          command = "${pkgs.prettier}/bin/prettier";
          options = [ "--write" ];
          includes = [
            "*.yaml"
            "*.yml"
          ];
          excludes = [ "secrets/*.yaml" ];
        };

        settings.formatter.prettier-markdown = {
          command = "${pkgs.prettier}/bin/prettier";
          options = [
            "--write"
            "--prose-wrap"
            "always"
          ];
          includes = [ "*.md" ];
        };
      };
    };
}
