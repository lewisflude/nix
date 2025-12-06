{ pkgs, ... }:
let
  steamRunUrl = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [ pkgs.coreutils ];
  };

  # Lutris launcher that uses systemd to get proper file descriptor limits
  lutris-systemd = pkgs.writeShellScriptBin "lutris-systemd" ''
    exec ${pkgs.systemd}/bin/systemd-run --user --scope --unit=lutris \
      --property="LimitNOFILE=1048576" \
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

  # Create a desktop entry that launches Lutris with proper ESYNC limits
  # This overrides the default Lutris desktop entry to use systemd-run
  # Note: This assumes Lutris is installed at the system level via gaming feature
  xdg.desktopEntries.lutris = {
    name = "Lutris";
    comment = "Install and play games (with ESYNC support)";
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
