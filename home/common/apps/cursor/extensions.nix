# Cursor/VSCode Extensions Configuration
# Comprehensive extension collection organized by category for senior developers
# Modular design allows for easy customization and selective loading

{ pkgs, ... }:

let
  vsc = pkgs.vscode-extensions;

  # ==== CORE THEME & UI EXTENSIONS ====
  themes = [
  ];

  # ==== ESSENTIAL PRODUCTIVITY EXTENSIONS ====
  productivity = [
    vsc.usernamehw.errorlens
    vsc.christian-kohler.path-intellisense
    vsc.redhat.vscode-yaml
    vsc.yoavbls.pretty-ts-errors

  ];

  # ==== CORE PROGRAMMING LANGUAGES ====
  coreLangs = [
    vsc.jnoortheen.nix-ide
    vsc.rust-lang.rust-analyzer
    vsc.bradlc.vscode-tailwindcss
  ];

  # ==== EXTENDED PROGRAMMING LANGUAGES ====
  extraLangs = [
    vsc.golang.go
    vsc.shd101wyy.markdown-preview-enhanced
    vsc.bierner.markdown-mermaid
    vsc.sumneko.lua # Lua language server (Love2D development)
  ];

  # ==== DEVELOPMENT TOOLING ====
  devTools = [
    vsc.mkhl.direnv
    vsc.biomejs.biome
  ];

  # ==== GIT & VERSION CONTROL ====
  git = [
    vsc.eamodio.gitlens
    vsc.github.vscode-pull-request-github # Re-enabled - compatibility issues likely resolved
  ];

  # ==== DEBUGGING & TESTING ====
  debugging = [
    # Keep minimal - only add if you actually use testing
  ];

  # ==== DATABASE & DATA TOOLS ====
  database = [
    # Keep minimal - only add if you work with databases
  ];

  # ==== DEVOPS & INFRASTRUCTURE ====
  devops = [
    vsc.ms-vscode-remote.remote-containers
    # Removed Kubernetes tools - add only if needed
  ];

  # ==== WEB DEVELOPMENT ====
  webDev = [
    vsc.ms-vscode.vscode-typescript-next
    vsc.ms-vscode.vscode-css-peek
    vsc.ms-vscode.vscode-json
    vsc.ms-vscode.vscode-eslint
  ];

  codeQuality = [
    vsc.ms-vscode.vscode-eslint # Already in webDev, but needed for essentials
    # Removed spell checker - add only if needed
  ];

  # ==== AI & ASSISTANCE ====

  # ==== OPTIONAL/SPECIALIZED EXTENSIONS ====
  specialized = [

  ];

  # ==== EXTENSION SETS COMPOSITION ====
  extSets = {
    inherit themes productivity;

    # Core languages that most developers need
    coreLangs = coreLangs;

    # Extended language support
    extraLangs = extraLangs;

    # Development tooling essentials
    tooling = devTools;

    # Git and version control
    git = git;

    # Developer experience improvements
    dx = productivity ++ debugging; # Combine productivity and debugging

    # DevOps and infrastructure
    devops = devops;

    # Web development specific
    webDev = webDev;

    # Database and data tools
    database = database;

    # Code quality and analysis
    codeQuality = codeQuality;

    # Specialized/optional extensions
    specialized = specialized;
  };

  # ==== CURATED EXTENSION COLLECTIONS ====

  # Essential extensions every developer should have
  essentials = themes ++ productivity ++ coreLangs ++ git ++ devTools;

  # Full-stack developer collection
  fullStack = essentials ++ extraLangs ++ webDev ++ database;

  # DevOps engineer collection
  devopsEngineer = essentials ++ devops ++ database;

  # Backend developer collection
  backend = essentials ++ extraLangs ++ database ++ devops;

  # Frontend developer collection
  frontend = essentials ++ webDev;

in
{
  inherit extSets;

  # Primary extension list (essentials + commonly used)
  extensions = essentials ++ extraLangs;

  # Alternative curated collections
  inherit
    essentials
    fullStack
    devopsEngineer
    backend
    frontend
    ;

  # Individual categories for custom composition
  inherit
    themes
    productivity
    coreLangs
    extraLangs
    devTools
    git
    debugging
    database
    devops
    webDev
    codeQuality
    specialized
    ;
}
