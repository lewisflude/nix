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
  "ai.blmt.io" = mkReverseProxy "localhost:7000"; # Open WebUI

  "comfy.blmt.io" = mkReverseProxy "localhost:8188";

  # Ollama - with CORS headers
  "ollama.blmt.io" = {
    extraConfig = ''
      reverse_proxy localhost:11434 {
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
