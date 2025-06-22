{
  imports = [
    ./editor.nix
    ./browser.nix
    ./media.nix
    ./messaging.nix
    ./password-management.nix
    # Individual program configs are imported by specific modules
    ./bat.nix
    ./direnv.nix
    ./fzf.nix
    ./ripgrep.nix
    ./zoxide.nix
  ];
}
