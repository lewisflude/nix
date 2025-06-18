# Cursor/VSCode Extensions Configuration
# Organized by category for easy maintenance

{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    # Themes & UI
    catppuccin.catppuccin-vsc # Catppuccin theme

    # Core Languages
    jnoortheen.nix-ide
    rust-lang.rust-analyzer

    # Development Tools
    mkhl.direnv
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    biomejs.biome

    # Git Integration
    eamodio.gitlens
    github.vscode-pull-request-github

    # Developer Experience
    usernamehw.errorlens # Inline error/warning display
    yoavbls.pretty-ts-errors # Human-readable TypeScript errors
    redhat.vscode-yaml # YAML validation & IntelliSense
    christian-kohler.path-intellisense # File path autocomplete
    formulahendry.auto-rename-tag # Auto rename HTML/JSX tags

    # Additional Languages
    ms-python.python # Python language support
    ms-python.pylint # Python linting
    ms-python.black-formatter # Python Black formatter
    golang.go # Go language support
    timonwong.shellcheck # Shell script linting
    foxundermoon.shell-format # Shell script formatting
    ms-vscode-remote.remote-containers # Docker development
    ms-azuretools.vscode-docker # Docker formatter and support
    davidanson.vscode-markdownlint # Markdown linting
  ];
}
