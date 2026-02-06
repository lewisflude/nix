# VR Module - WiVRn + xrizer for Quest headsets
# References:
# - https://lvra.gitlab.io/docs/distros/nixos/
# - https://wiki.nixos.org/wiki/VR
{ config, ... }:
{
  flake.modules.nixos.vr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      wivrnPkg = pkgs.wivrn-multilib;
    in
    {
      services.wivrn = {
        enable = true;
        package = wivrnPkg;
        defaultRuntime = true;
        openFirewall = true;
        steam.importOXRRuntimes = true;
      };

      # FIXME: Remove when https://github.com/NixOS/nixpkgs/issues/482152 is fixed
      systemd.user.services.wivrn.serviceConfig.ExecStart =
        let
          cfg = config.services.wivrn;
          configFormat = pkgs.formats.json { };
          configFile = configFormat.generate "config.json" cfg.config.json;
        in
        lib.mkForce "${wivrnPkg}/bin/wivrn-server -f ${configFile}";

      environment.systemPackages = [ pkgs.android-tools ];
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
      # xrizer OpenVR paths - points to nix store (accessible via PRESSURE_VESSEL_FILESYSTEMS_RO)
      xdg.configFile."openvr/openvrpaths.vrpath" = {
        force = true;
        text = builtins.toJSON {
          version = 1;
          jsonid = "vrpathreg";
          external_drivers = null;
          config = [ "${config.xdg.dataHome}/Steam/config" ];
          log = [ "${config.xdg.dataHome}/Steam/logs" ];
          runtime = [ "${pkgs.xrizer-multilib}/lib/xrizer" ];
        };
      };
    };
}
