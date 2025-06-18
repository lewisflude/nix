# Cursor/VSCode Extensions Configuration
# Organized by category for easy maintenance

{ pkgs, ... }:
{
  extensions = with pkgs.vscode-extensions; [
    # Core Languages
    jnoortheen.nix-ide
    rust-lang.rust-analyzer
    
    # Development Tools
    mkhl.direnv
    bradlc.vscode-tailwindcss
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    biomejs.biome
    
    # Git Integration
    eamodio.gitlens
    github.vscode-pull-request-github
    
    # Developer Experience
    usernamehw.errorlens # Inline error/warning display
    yoavbls.pretty-ts-errors # Human-readable TypeScript errors
    redhat.vscode-yaml # YAML validation & IntelliSense
    
    # Additional Languages
    ms-python.python # Python language support
    ms-python.pylint # Python linting
    golang.go # Go language support
    timonwong.shellcheck # Shell script linting
    ms-vscode-remote.remote-containers # Docker development
    davidanson.vscode-markdownlint # Markdown linting
  ];
}