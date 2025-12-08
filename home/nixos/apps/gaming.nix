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
  lutris-systemd = pkgs.writeShellScriptBin "lutris-systemd" ''
    exec ${pkgs.systemd}/bin/systemd-run --user --scope \
      --property="LimitNOFILE=1048576:1048576" \
      ${pkgs.lutris}/bin/lutris "$@"
  '';
in
{
  programs.mangohud = {
    enable = true;
    package = pkgs.mangohud_git; # Chaotic Nyx bleeding-edge version
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
