{ lib, ... }:
let
  mimeDefaults = lib.genAttrs [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ] (_: [ "chromium-browser.desktop" ]);
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = mimeDefaults;
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
    ];
  };
}
