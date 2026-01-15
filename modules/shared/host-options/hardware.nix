{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.host.hardware = {
    gpuID = mkOption {
      type = types.str;
      default = "";
      description = ''
        PCI device ID for primary GPU in vendor:device format.
        Used by gamescope and other tools to explicitly target the correct GPU.
        Find with: lspci -nn | grep VGA
        Example: "10de:2684" for RTX 4090
      '';
      example = "10de:2684";
    };

    renderDevice = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        DRM render device path for Wayland compositors on multi-GPU systems.
        Forces the compositor to use a specific GPU for rendering.
        Find with: ls -la /dev/dri/
        Example: "/dev/dri/renderD129" for discrete GPU on multi-GPU system
      '';
      example = "/dev/dri/renderD129";
    };
  };
}
