# AI Services Virtual Hosts
# ComfyUI, Ollama, Open WebUI, etc.
{
  lib,
  ...
}:
let
  helpers = import ../helpers.nix { inherit lib; };
  inherit (helpers) mkReverseProxy;
in
{
  "ai.blmt.io" = mkReverseProxy "127.0.0.1:7000"; # Open WebUI

  "comfy.blmt.io" = mkReverseProxy "127.0.0.1:8188";

  # Ollama - with CORS headers
  "ollama.blmt.io" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:11434 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
      encode zstd gzip
      @options {
        method OPTIONS
      }
      header {
        Access-Control-Allow-Origin *
        Access-Control-Allow-Credentials true
        Access-Control-Allow-Methods *
        Access-Control-Allow-Headers *
        defer
      }
    '';
  };
}
