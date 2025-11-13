{ pkgs, ... }:
let
  steamRunUrl = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [ pkgs.coreutils ];
  };
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
  ];
}
