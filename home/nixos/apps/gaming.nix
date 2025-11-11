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
  home.packages =
    (with pkgs; [

      mangohud_git # Chaotic Nyx bleeding-edge version
      protonup-qt
      (sunshine.override { cudaSupport = true; })
      moonlight-qt
    ])
    ++ [ steamRunUrl ];
}
