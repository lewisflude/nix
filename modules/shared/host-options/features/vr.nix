# Virtual Reality Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  vr = {
    enable = mkEnableOption "virtual reality support and optimizations";
    alvr = mkEnableOption "ALVR wireless VR streaming" // {
      default = true;
    };
    monado = mkEnableOption "Monado OpenXR runtime" // {
      default = true;
    };
    wivrn = {
      enable = mkEnableOption "WiVRn wireless VR streaming";
      autoStart = mkEnableOption "Start WiVRn service automatically on boot";
      defaultRuntime = mkEnableOption "Set WiVRn as default OpenXR runtime";
      openFirewall = mkEnableOption "Open firewall ports for WiVRn" // {
        default = true;
      };
    };
    immersed = {
      enable = mkEnableOption "Immersed VR desktop productivity app";
      openFirewall = mkEnableOption "Open firewall ports for Immersed" // {
        default = true;
      };
    };
    virtualMonitors = {
      enable = mkEnableOption "virtual monitor support for VR productivity (Immersed)";
      method = mkOption {
        type = types.enum [
          "hardware"
          "auto"
        ];
        default = "hardware";
        description = ''
          Method for creating virtual monitors:
          - hardware: Use dummy HDMI/DisplayPort adapters (recommended for X11 and Wayland)
          - auto: Automatically detect best method (future: native Wayland protocol support)
        '';
        example = "auto";
      };
      hardwareAdapterCount = mkOption {
        type = types.int;
        default = 3;
        description = "Expected number of dummy HDMI/DP adapters for virtual monitors";
        example = 3;
      };
      defaultResolution = mkOption {
        type = types.str;
        default = "3840x1600";
        description = "Default resolution for virtual monitors (ultra-wide recommended for VR)";
        example = "1920x1080";
      };
      diagnosticTools = mkEnableOption "install diagnostic tools (pciutils, wlr-randr)" // {
        default = true;
      };
    };
    opencomposite = mkEnableOption "OpenComposite (OpenVR to OpenXR translation)";
    steamvr = mkEnableOption "SteamVR support";
    sidequest = mkEnableOption "SideQuest for Quest sideloading" // {
      default = true;
    };
    performance = mkEnableOption "VR-specific performance optimizations" // {
      default = true;
    };
  };
}
