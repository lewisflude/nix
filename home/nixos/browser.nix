{ pkgs, lib, ... }:

let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in
{
  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;

      extensions = {
        force = true;
        packages = with addons; [
          ublock-origin
          kagi-search
          onepassword-password-manager
        ];
      };

      search = {
        default = "Kagi";
        order = [ "Kagi" ];
        engines.Kagi = {
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          definedAliases = [ "@k" ];
        };
      };

      settings = {
        # Hardware acceleration and performance
        "media.hardware-video-decoding.enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "layers.acceleration.force-enabled" = true;
        "gfx.webrender.all" = true;
        "webgl.force-enabled" = true;
        "layers.offmainthreadcomposition.enabled" = true;
        "gfx.canvas.azure.accelerated" = true;
        "layers.async-video.enabled" = true;
        "gfx.x11-egl.force-enabled" = true;

        # Memory management
        "browser.tabs.unloadOnLowMemory" = true;

        # Privacy and telemetry
        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.strictMode.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.resistFingerprinting" = true;
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;

      };
    };
  };

}
