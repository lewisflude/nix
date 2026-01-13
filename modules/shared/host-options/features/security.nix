# Security Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  security = {
    enable = mkEnableOption "security and privacy tools" // {
      example = true;
    };
    yubikey = mkEnableOption "YubiKey hardware support" // {
      example = true;
    };
    gpg = mkEnableOption "GPG/PGP encryption" // {
      example = true;
    };
    firewall = mkEnableOption "advanced firewall configuration (NixOS only)" // {
      example = true;
    };
    fail2ban = mkEnableOption "fail2ban intrusion detection (NixOS only)" // {
      example = true;
    };
  };
}
