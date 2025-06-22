{
  imports = [
    # ./terminal.nix  # Temporarily disabled
    ./editor.nix
    ./browser.nix
    ./media.nix
    ./messaging.nix
    ./password-management.nix
    ./yubikey-touch-detector.nix
    ./waybar.nix
    ./mangohud.nix
    ./version-control.nix
    # Individual program configs are imported by specific modules
    ./bat.nix
    ./direnv.nix
    ./fzf.nix
    ./ripgrep.nix
    ./zoxide.nix
  ];
}
