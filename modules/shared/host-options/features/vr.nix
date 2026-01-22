# Virtual Reality Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  vr = {
    enable = mkEnableOption "virtual reality support and optimizations" // {
      example = true;
    };
    wivrn = {
      enable = mkEnableOption "WiVRn wireless VR streaming (includes embedded Monado)" // {
        example = true;
      };
      autoStart = mkEnableOption "Start WiVRn service automatically on boot" // {
        example = true;
      };
      defaultRuntime = mkEnableOption "Set WiVRn as default OpenXR runtime" // {
        example = true;
      };
      openFirewall = mkEnableOption "Open firewall ports for WiVRn" // {
        default = true;
        example = true;
      };
    };
    immersed = {
      enable = mkEnableOption "Immersed VR desktop productivity app" // {
        example = true;
      };
      openFirewall = mkEnableOption "Open firewall ports for Immersed" // {
        default = true;
        example = true;
      };
    };
    steamvr = mkEnableOption "SteamVR support with 32-bit libraries" // {
      example = true;
    };
    performance = mkEnableOption "VR-specific performance optimizations" // {
      default = true;
      example = true;
    };
  };
}
