# power.nix
{ pkgs, ... }: {
  services.power-profiles-daemon.enable = true;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
      };
      custom = {
        start = "${pkgs.coreutils}/bin/echo 'gamemode start'";
        end = "${pkgs.coreutils}/bin/echo 'gamemode end'";
      };
    };
  };
}
