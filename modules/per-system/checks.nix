# Per-system checks via git-hooks.nix
# Dendritic pattern: Provides pre-commit checks for each system
{ inputs, ... }:
{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem =
    _:
    {
      pre-commit.settings = {
        excludes = [ "secrets/.*\\.yaml$" ];

        hooks = {
          # Formatting (auto-linked to treefmt-nix)
          treefmt.enable = true;

          # Commit message validation
          commitizen.enable = true;

          # Markdown linting
          markdownlint.enable = true;
        };
      };
    };
}
