{
  config,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  vrEnabled = osConfig.host.features.vr.enable or false;

  # Helper script to install Media Foundation codecs for Heresphere
  # Media Foundation is required for proper video codec support in Windows VR apps
in
mkIf vrEnabled {
  # User VR packages
  # Note: Immersed VR is installed via programs.immersed module at system level
  home.packages = [
    # WayVR - Desktop overlay for VR (merged from wlx-overlay-s + wayvr-dashboard)
    # Provided by nixpkgs-xr overlay for latest version
    pkgs.wayvr
  ];

  xdg.configFile."openvr/openvrpaths.vrpath".text =
    let
      steam = "${config.xdg.dataHome}/Steam";
    in
    builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";

      external_drivers = null;
      config = [ "${steam}/config" ];

      log = [ "${steam}/logs" ];

      "runtime" = [
        "${pkgs.xrizer}/lib/xrizer"
        # OR
        #"${pkgs.opencomposite}/lib/opencomposite"
      ];
    };

}
