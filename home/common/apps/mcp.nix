{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    uv
  ];
  services.mcp.enable = true;
  services.mcp.servers = {
    # kagi = {
    #   command = "${pkgs.uv}/bin/uvx";
    #   args = [ "kagimcp" ];
    #   env = {
    #     KAGI_API_KEY = config.sops.secrets.KAGI_API_KEY.path;
    #   };
    #   port = 11431;
    # };
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
        PATH = "${pkgs.nodejs_22}/bin" + ":" + (builtins.getEnv "PATH");
      };
      port = 11435;
    };

  };
}
