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
    kagi = {
      command = "uvx";
      args = [ "kagimcp" ];
      env = {
        KAGI_API_KEY = config.sops.secrets.KAGI_API_KEY.path;
      };
      port = 11431;
    };
  };
}
