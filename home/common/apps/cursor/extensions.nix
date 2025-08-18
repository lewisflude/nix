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
    vsc.redhat.vscode-yaml
    vsc.yoavbls.pretty-ts-errors
  ];

  # ==== CORE PROGRAMMING LANGUAGES ====
  coreLangs = [
    vsc.jnoortheen.nix-ide
    vsc.bradlc.vscode-tailwindcss
    vsc.rust-lang.rust-analyzer # Rust language server with advanced analysis
    vsc.tamasfe.even-better-toml # Enhanced TOML support for Cargo.toml
  ];

  # ==== EXTENDED PROGRAMMING LANGUAGES ====
  extraLangs = [
    vsc.sumneko.lua # Lua language server (Love2D development)
  ];

  # ==== DEVELOPMENT TOOLING ====
  devTools = [
    vsc.mkhl.direnv
    vsc.biomejs.biome
  ];

  # ==== GIT & VERSION CONTROL ====
  git = [
  ];

  # ==== DEBUGGING & TESTING ====
  debugging = [
    # Keep minimal - only add if you actually use testing
    vsc.vadimcn.vscode-lldb # Native debugger for Rust/C++ using LLDB
  ];

  # ==== DATABASE & DATA TOOLS ====
  database = [
    # Keep minimal - only add if you work with databases
  ];

  # ==== DEVOPS & INFRASTRUCTURE ====
  devops = [
    # Removed Kubernetes tools - add only if needed
  ];

  # ==== WEB DEVELOPMENT ====
  webDev = [
    vsc.ms-vscode.vscode-typescript-next
    vsc.ms-vscode.vscode-css-peek
    vsc.ms-vscode.vscode-json
  ];

  codeQuality = [
    vsc.usernamehw.errorlens # Enhanced error/warning display inline
  ];

  # ==== AI & ASSISTANCE ====

  # ==== OPTIONAL/SPECIALIZED EXTENSIONS ====
  specialized = [
    vsc.serayuzgur.crates # Rust crate dependency management and version info
  ];

  # ==== EXTENSION SETS COMPOSITION ====
  extSets = {
    inherit themes productivity;

    # Core languages that most developers need
    inherit coreLangs;

    # Extended language support
    inherit extraLangs;

    # Development tooling essentials
    tooling = devTools;

    # Git and version control
    inherit git;

    # Developer experience improvements
    dx = productivity ++ debugging; # Combine productivity and debugging

    # DevOps and infrastructure
    inherit devops;

    # Web development specific
    inherit webDev;

    # Database and data tools
    inherit database;

    # Code quality and analysis
    inherit codeQuality;

    # Specialized/optional extensions
    inherit specialized;
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
