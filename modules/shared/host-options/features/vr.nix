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
    enable = mkEnableOption "virtual reality support and optimizations";
    wivrn = {
      enable = mkEnableOption "WiVRn wireless VR streaming (includes embedded Monado)";
      autoStart = mkEnableOption "Start WiVRn service automatically on boot";
      defaultRuntime = mkEnableOption "Set WiVRn as default OpenXR runtime";
      openFirewall = mkEnableOption "Open firewall ports for WiVRn" // { default = true; };
    };
    alvr = {
      enable = mkEnableOption "ALVR wireless VR streaming (uses SteamVR)";
      autoStart = mkEnableOption "Start ALVR service automatically on boot";
      defaultRuntime = mkEnableOption "Set ALVR as default OpenXR runtime";
      openFirewall = mkEnableOption "Open firewall ports for ALVR" // { default = true; };
    };
    immersed = {
      enable = mkEnableOption "Immersed VR desktop productivity app";
      openFirewall = mkEnableOption "Open firewall ports for Immersed" // { default = true; };
    };
    steamvr = mkEnableOption "SteamVR support with 32-bit libraries";
    performance = mkEnableOption "VR-specific performance optimizations" // { default = true; };
  };
}
