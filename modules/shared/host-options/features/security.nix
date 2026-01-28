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
    enable = mkEnableOption "security and privacy tools";
    yubikey = mkEnableOption "YubiKey hardware support";
    gpg = mkEnableOption "GPG/PGP encryption";
    firewall = mkEnableOption "advanced firewall configuration (NixOS only)";
    fail2ban = mkEnableOption "fail2ban intrusion detection (NixOS only)";
  };
}
