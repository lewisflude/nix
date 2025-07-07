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
          web-scrobbler
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

      settings = lib.mkOverride 10 (
        lib.mkMerge [
          {
            "media.hardware-video-decoding.enabled" = true;
            "browser.tabs.unloadOnLowMemory" = true;
          }
          (lib.mkIf pkgs.stdenv.isLinux {
            "media.ffmpeg.vaapi.enabled" = true;
          })
          {
            "browser.sessionstore.resume_from_crash" = true;
            "signon.rememberSignons" = false;
            "toolkit.telemetry.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "extensions.pocket.enabled" = false;
          }
        ]
      );
    };
  };

  home.packages = with pkgs; [
    google-chrome
  ];
}
