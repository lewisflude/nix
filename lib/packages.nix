{ pkgs, configVars, lib }:

let
  nodeVersion = configVars.languages.node;
  pythonVersion = configVars.languages.python;
  pythonPkgVersion = builtins.replaceStrings ["."] [""] pythonVersion;
  pythonPkgs = pkgs."python${pythonPkgVersion}Packages";
  
in {
  nodejs = {
    core = with pkgs; [
      pkgs."nodejs_${nodeVersion}"
    ];
    
    tools = with pkgs; [
      biome
    ];
    
    full = with pkgs; [
      pkgs."nodejs_${nodeVersion}"
      biome
    ];
  };

  python = {
    core = with pkgs; [
      pkgs."python${pythonPkgVersion}"
      pythonPkgs.pip
      pythonPkgs.setuptools
      pythonPkgs.wheel
    ];
    
    tools = [
      pythonPkgs.uv
      pythonPkgs.black
      pythonPkgs.isort
      pythonPkgs.flake8
      pythonPkgs.mypy
      pythonPkgs.pytest
      pkgs.python-lsp-server
    ];
    
    full = with pkgs; [
      pkgs."python${pythonPkgVersion}"
      pythonPkgs.pip
      pythonPkgs.setuptools
      pythonPkgs.wheel
      pythonPkgs.uv
      pythonPkgs.black
      pythonPkgs.isort
      pythonPkgs.flake8
      pythonPkgs.mypy
      pythonPkgs.pytest
      python-lsp-server
    ];
  };

  rust = {
    core = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
    ];
    
    tools = with pkgs; [
      rust-analyzer
      cargo-watch
      cargo-edit
      cargo-audit
    ];
    
    full = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      cargo-watch
      cargo-edit
      cargo-audit
    ];
  };

  go = {
    core = with pkgs; [
      go
      gopls
      golangci-lint
    ];
    
    tools = with pkgs; [
      gotools
      go-tools
      delve
    ];
    
    full = with pkgs; [
      go
      gopls
      golangci-lint
      gotools
      go-tools
      delve
    ];
  };

  web = {
    core = with pkgs; [
      pkgs."nodejs_${nodeVersion}"
      biome
    ];
    
    tools = with pkgs; [
    ];
    
    full = with pkgs; [
      pkgs."nodejs_${nodeVersion}"
      biome
    ];
  };

  devops = {
    containers = with pkgs; [
      docker
      docker-compose
      podman
      podman-compose
    ];
    
    cloud = with pkgs; [
      terraform
      ansible
      kubectl
      awscli2
    ];
    
    monitoring = with pkgs; [
      htop
      btop
      iotop
      nethogs
    ];
    
    full = with pkgs; [
      docker
      docker-compose
      podman
      podman-compose
      terraform
      ansible
      kubectl
      awscli2
      htop
      btop
      iotop
      nethogs
    ];
  };

  common = {
    vcs = with pkgs; [
      git
      gh
      git-lfs
      lazygit
    ];
    
    editors = with pkgs; [
      neovim
      vscode
    ];
    
    network = with pkgs; [
      curl
      wget
      httpie
      jq
      yq
    ];
    
    full = with pkgs; [
      git
      gh
      git-lfs
      lazygit
      neovim
      vscode
      curl
      wget
      httpie
      jq
      yq
    ];
  };
}