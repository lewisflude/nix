# Cursor/VSCode Extensions Configuration
# Organized by category for easy maintenance

{ pkgs, lib, ... }:

# Expose extension categories as an attr-set so other modules (or
# different Cursor profiles) can pick exactly what they need.  The final
# list is the concatenation of all values.

let
  vsc = pkgs.vscode-extensions;

  extSets = {
    themes = [ vsc.catppuccin.catppuccin-vsc ];

    coreLangs = [
      vsc.jnoortheen.nix-ide
      vsc.rust-lang.rust-analyzer
    ];

    tooling = [
      vsc.mkhl.direnv
      vsc.bradlc.vscode-tailwindcss
      vsc.biomejs.biome
    ];

    git = [
      vsc.eamodio.gitlens
      vsc.github.vscode-pull-request-github
    ];

    dx = [
      vsc.usernamehw.errorlens
      vsc.yoavbls.pretty-ts-errors
      vsc.redhat.vscode-yaml
      vsc.christian-kohler.path-intellisense
      vsc.formulahendry.auto-rename-tag
    ];

    extraLangs = [
      vsc.ms-python.python
      vsc.ms-python.pylint
      vsc.ms-python.black-formatter
      vsc.golang.go
      vsc.timonwong.shellcheck
      vsc.foxundermoon.shell-format
      vsc.ms-vscode-remote.remote-containers
      vsc.ms-azuretools.vscode-docker
      vsc.davidanson.vscode-markdownlint
    ];
  };
in
{
  inherit extSets;

  # Flatten all category lists into a single list that Home-Manager
  # expects for programs.vscode.extensions.
  extensions = lib.concatLists (lib.attrValues extSets);
}
