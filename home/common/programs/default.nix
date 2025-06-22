{
  imports = [
    # ./terminal.nix  # Temporarily disabled
    ./editor.nix
    ./browser.nix
    ./media.nix
    ./messaging.nix
    ./password-management.nix
    ./version-control.nix
    ./file-manager.nix
    # Individual program configs are imported by specific modules
    ./bat.nix
    ./direnv.nix
    ./fzf.nix
    ./ripgrep.nix
    ./zoxide.nix
  ];
}
