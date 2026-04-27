# Font Configuration
# System-level font packages and fontconfig settings
_: {
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts = {
        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = [ "Iosevka Nerd Font" ];
            sansSerif = [ "Iosevka" ];
            serif = [ "Iosevka" ];
          };
          subpixel = {
            rgba = "rgb";
            lcdfilter = "default";
          };
          hinting = {
            enable = true;
            style = "slight";
          };
          antialias = true;
        };

        fontDir.enable = true;

        packages = [
          pkgs.iosevka-bin
          pkgs.nerd-fonts.iosevka
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-color-emoji
        ];
      };
    };
}
