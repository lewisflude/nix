# Cursor/VSCode Extensions Configuration
# Comprehensive extension collection organized by category for senior developers
# Modular design allows for easy customization and selective loading

{ pkgs, lib, ... }:

let
  vsc = pkgs.vscode-extensions;

  # ==== CORE THEME & UI EXTENSIONS ====
  themes = [
    vsc.catppuccin.catppuccin-vsc
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
    vsc.ms-python.python
    vsc.ms-python.pylint
    vsc.ms-python.black-formatter
    vsc.golang.go
    vsc.shd101wyy.markdown-preview-enhanced
    vsc.bierner.markdown-mermaid
  ];

  # ==== DEVELOPMENT TOOLING ====
  devTools = [
    vsc.mkhl.direnv
    vsc.biomejs.biome
  ];

  # ==== GIT & VERSION CONTROL ====
  git = [
    vsc.eamodio.gitlens
    vsc.github.vscode-pull-request-github
  ];

  # ==== DEBUGGING & TESTING ====
  debugging = [

  ];

  # ==== DATABASE & DATA TOOLS ====
  database = [

  ];

  # ==== DEVOPS & INFRASTRUCTURE ====
  devops = [
    vsc.ms-azuretools.vscode-docker
    vsc.ms-vscode-remote.remote-containers
  ];

  # ==== WEB DEVELOPMENT ====
  webDev = [
    vsc.ms-vscode.vscode-typescript-next
    vsc.ms-vscode.vscode-css-peek
  ];

  codeQuality = [

  ];

  # ==== AI & ASSISTANCE ====
  aiTools = [

  ];

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
