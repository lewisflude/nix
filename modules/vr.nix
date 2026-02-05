# VR Module - WiVRn for Quest headsets
# Reference: https://lvra.gitlab.io/docs/distros/nixos/
# Packages from nixpkgs-xr overlay (wivrn, xrizer, wayvr, etc.)
{ config, ... }:
{
  flake.modules.nixos.vr =
    { pkgs, ... }:
    {
      services.wivrn = {
        enable = true;
        package = pkgs.wivrn.override { cudaSupport = true; };
        defaultRuntime = true;
        openFirewall = true;

        # Auto-launch WayVR when headset connects
        config.json.application = [ pkgs.wayvr ];
      };

      # ADB for Quest debugging and sideloading
      programs.adb.enable = true;
      users.users.${config.username}.extraGroups = [ "adbusers" ];
    };

  flake.modules.homeManager.vr =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf (osConfig.services.wivrn.enable or false) {
      # OpenXR runtime for sandboxed Steam apps
      xdg.configFile."openxr/1/active_runtime.json".source =
        "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";

      # OpenVR paths for xrizer (from nixpkgs-xr)
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
          runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
        };
    };
}
