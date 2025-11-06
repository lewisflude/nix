{
  config,
  lib,
  pkgs,
  ...
}:
{

  _module.args = lib.mkIf (config == null) { };
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;

    allowed-origins = [
      "https://localhost:9090"
      "http://localhost:9090"
      "https://jupiter:9090"
      "http://jupiter:9090"
      "https://cockpit.blmt.io"
      "http://cockpit.blmt.io"
    ];
    settings = {
      WebService = {

        AllowUnencrypted = true;

        ProtocolHeader = "X-Forwarded-Proto";

        ForwardedForHeader = "X-Forwarded-For";
      };
    };
  };

  environment.systemPackages = with pkgs; [

  ];
}
