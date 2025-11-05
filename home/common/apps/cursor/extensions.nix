{ pkgs, ... }:
let
  vsc = pkgs.vscode-extensions;
  themes = [
  ];
  productivity = [
    vsc.redhat.vscode-yaml
    vsc.yoavbls.pretty-ts-errors
  ];
  coreLangs = [
    vsc.jnoortheen.nix-ide
    vsc.bradlc.vscode-tailwindcss
    # vsc.rust-lang.rust-analyzer # Temporarily disabled due to build error with keytar on macOS
    vsc.tamasfe.even-better-toml
  ];
  extraLangs = [
    vsc.sumneko.lua
  ];
  devTools = [
    vsc.mkhl.direnv
    vsc.biomejs.biome
  ];
  git = [
  ];
  debugging = [
    vsc.vadimcn.vscode-lldb
  ];
  database = [
  ];
  devops = [
  ];
  webDev = [
    vsc.ms-vscode.vscode-typescript-next
    vsc.ms-vscode.vscode-css-peek
    vsc.ms-vscode.vscode-json
  ];
  codeQuality = [
    vsc.usernamehw.errorlens
  ];
  specialized = [
    vsc.serayuzgur.crates
  ];
  extSets = {
    inherit themes productivity;
    inherit coreLangs;
    inherit extraLangs;
    tooling = devTools;
    inherit git;
    dx = productivity ++ debugging;
    inherit devops;
    inherit webDev;
    inherit database;
    inherit codeQuality;
    inherit specialized;
  };
  essentials = themes ++ productivity ++ coreLangs ++ git ++ devTools;
  fullStack = essentials ++ extraLangs ++ webDev ++ database;
  devopsEngineer = essentials ++ devops ++ database;
  backend = essentials ++ extraLangs ++ database ++ devops;
  frontend = essentials ++ webDev;
in
{
  inherit extSets;
  extensions = essentials ++ extraLangs;
  inherit
    essentials
    fullStack
    devopsEngineer
    backend
    frontend
    ;
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
