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

  home.packages =
    (with pkgs; [
      protonup-qt
      (sunshine.override { cudaSupport = true; })
      moonlight-qt
    ])
    ++ [ steamRunUrl ];
}
