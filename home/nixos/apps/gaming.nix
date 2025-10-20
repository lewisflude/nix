{pkgs, ...}: let
  steamRunUrl = pkgs.writeShellApplication {
    name = "steam-run-url";
    text = ''
      echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
    '';
    runtimeInputs = [pkgs.coreutils];
  };
in {
  home.packages =
    (with pkgs; [
      # lutris  # Temporarily disabled due to pyrate-limiter build failure
      mangohud
      protonup-qt
      (sunshine.override {cudaSupport = true;})
      moonlight-qt
      dwarf-fortress
    ])
    ++ [steamRunUrl];
}
