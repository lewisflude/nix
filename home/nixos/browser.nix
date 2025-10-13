{
  pkgs,
  lib,
  ...
}: let
  desktopFile = "chromium-browser.desktop";
  webMimeTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];
  addons = pkgs.nur.repos.rycee.firefox-addons;
  mimeDefaults = lib.genAttrs webMimeTypes (_type: [desktopFile]);
in {
  home.packages = [
  ];
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = mimeDefaults;
  };
  xdg.desktopEntries = {
    "chromium-dev" = {
      name = "Chromium (Developer)";
      comment = "Chromium with dev tools and separate profile for development";
      exec = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --user-data-dir=/tmp/chromium-dev-session --auto-open-devtools-for-tabs --no-default-browser-check --no-first-run";
      icon = "chromium";
      type = "Application";
      categories = [
        "Development"
        "WebBrowser"
      ];
      terminal = false;
    };
    "chromium-incognito" = {
      name = "Chromium (Incognito)";
      comment = "Chromium in private browsing mode";
      exec = "${pkgs.chromium}/bin/chromium --enable-features=UseOzonePlatform --ozone-platform=wayland --incognito";
      icon = "chromium";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      terminal = false;
    };
  };
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";
      extensions = {
        force = true;
        packages = with addons; [
          ublock-origin
          privacy-badger
          kagi-search
          onepassword-password-manager
          firefox-color
          clearurls
          decentraleyes
        ];
      };
      search = {
        force = true;
        default = "Kagi";
        order = ["Kagi"];
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
          definedAliases = ["@k"];
        };
      };
      settings = {
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "media.ffmpeg.vaapi.enabled" = true;
        "devtools.chrome.enabled" = true;
        "devtools.debugger.remote-enabled" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
      };
      userChrome = ''
        
        :root[inFullscreen]
      '';
    };
  };
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    extensions = [
      "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"
      "cdglnehniifkbagbbombnjghhcihifij"
      "aapbdbdomjkkjkaonfhkkikfgjllcleb"
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa"
    ];
    commandLineArgs = [
      "--enable-features=UseOzonePlatform,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,AcceleratedVideoEncoder,VaapiVideoDecoder"
      "--ozone-platform=wayland"
      "--use-gl=desktop"
      "--ignore-gpu-blocklist"
      "--enable-zero-copy"
      "--enable-gpu-rasterization"
    ];
  };
}
