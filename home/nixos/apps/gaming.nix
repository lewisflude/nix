{ pkgs, ... }:
let
  steamRunUrl = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [ pkgs.coreutils ];
  };

  # Lutris wrapper to ensure ESYNC limits are set explicitly
  # System-wide limits are configured in modules/nixos/features/gaming.nix
  # but this ensures limits are set even if launched outside systemd scope
  # Also sets explicit Vulkan ICD path to prevent GPU detection failures
  lutris-systemd = pkgs.writeShellScriptBin "lutris-systemd" ''
    # Explicitly set NVIDIA Vulkan ICD to prevent intermittent detection failures
    # This fixes "GPU outdated" errors caused by Vulkan loader timing issues
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json

    # Ensure DXVK uses the correct Vulkan device (fix for multi-GPU systems)
    export DXVK_FILTER_DEVICE_NAME="NVIDIA"

    exec ${pkgs.systemd}/bin/systemd-run --user --scope \
      --property="LimitNOFILE=1048576:1048576" \
      ${pkgs.lutris}/bin/lutris "$@"
  '';
in
{
  programs.mangohud = {
    enable = true;
    package = pkgs.mangohud;
    enableSessionWide = false; # Only enable when needed via env var
  };

  home.packages = [
    # User-facing gaming applications
    # Note: protonup-qt is provided at system level
    # Note: sunshine service is configured at system level
    pkgs.moonlight-qt
    pkgs.wine
    pkgs.winetricks
    steamRunUrl
    lutris-systemd
  ];

  # Override desktop entry to use wrapper with ESYNC limits
  xdg.desktopEntries.lutris = {
    name = "Lutris";
    exec = "${lutris-systemd}/bin/lutris-systemd %U";
    icon = "lutris";
    categories = [ "Game" ];
    mimeType = [
      "x-scheme-handler/lutris"
      "application/x-lutris-game"
    ];
    terminal = false;
    type = "Application";
  };
}
