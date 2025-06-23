{ pkgs, lib, system, ... }: {
  home.packages = lib.optionals (lib.hasInfix "linux" system) (with pkgs; [
    usbutils
    evhz
    piper
  ]);

  services.udiskie = lib.mkIf (lib.hasInfix "linux" system) {
    enable = true;
    settings = {
      # workaround for
      # https://github.com/nix-community/home-manager/issues/632
      program_options = {
        # replace with your favorite file manager
        file_manager = "${pkgs.nautilus}/bin/nautilus";
      };
    };
  };

}
