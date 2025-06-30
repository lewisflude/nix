{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    uv
  ];

  home.file."bin/kagi-mcp-wrapper".text = ''
    #!/usr/bin/env bash
    export KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
    exec ${pkgs.uv}/bin/uvx kagimcp "$@"
  '';
  home.file."bin/kagi-mcp-wrapper".executable = true;

  services.mcp.enable = true;
  services.mcp.targets = {
    cursor = {
      directory = "${config.home.homeDirectory}/.cursor";
      fileName = "mcp.json";
    };
  };
  services.mcp.servers = {
    kagi = {
      command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = 11431;
      env = {
        KAGI_API_KEY = config.sops.secrets.KAGI_API_KEY.path;
      };
    };
    fetch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [ "mcp-server-fetch" ];
      port = 11432;
    };
    git = {
      command = "${pkgs.docker}/bin/docker";
      args = [
        "run"
        "-i"
        "--rm"
        "--mount"
        "type=bind,source=/Users/lewisflude/Code,dst=/Users/lewisflude/Code"
        "mcp/git"
      ];
      port = 11434;
    };
    nx = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "nx-mcp@latest"
        "/Users/lewisflude/Code/dex-web"
      ];
      port = 11435;
    };
    sequentialThinking = {
      command = "${pkgs.docker}/bin/docker";
      args = [
        "run"
        "--rm"
        "-i"
        "mcp/sequentialthinking"
      ];
      env = {
        PATH = "${pkgs.nodejs_24}/bin" + ":" + (builtins.getEnv "PATH");
      };
      port = 11435;
    };

  };
}
