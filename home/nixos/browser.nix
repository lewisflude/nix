# Chromium Browser Configuration
# Note: NIXOS_OZONE_WL is set in niri/default.nix (compositor-level)
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
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      "cdglnehniifkbagbbombnjghhcihifij" # uBlock Origin Lite
      "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
    ];
    commandLineArgs = [
      # Wayland + NVIDIA hardware acceleration
      "--ozone-platform=wayland"
      "--enable-features=VaapiOnNvidiaGPUs,VaapiVideoDecoder,Vulkan"
      "--ignore-gpu-blocklist"
      "--enable-gpu-rasterization"
    ];
  };
}
