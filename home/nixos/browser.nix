{
  pkgs,
  lib,
  ...
}:
let
  desktopFile = "chromium-browser.desktop";
  webMimeTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];
  mimeDefaults = lib.genAttrs webMimeTypes (_type: [ desktopFile ]);
in
{
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
