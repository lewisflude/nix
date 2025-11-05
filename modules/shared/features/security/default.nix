# Security feature module (cross-platform)
# Controlled by host.features.security.*
# Provides YubiKey, GPG, firewall, and other security tools
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.security;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
in
{
  config = mkIf cfg.enable {
    # NixOS-specific security configuration
    security = mkIf isLinux {
      # DOAS configuration (alternative to sudo)
      doas = {
        enable = true;
        extraRules = [
          {
            users = [ config.host.username ];
            keepEnv = true;
            persist = true;
          }
        ];
      };

      # PAM configuration for U2F/YubiKey
      pam = {
        services = {
          login.u2fAuth = cfg.yubikey;
          sudo.u2fAuth = cfg.yubikey;
          greetd.u2fAuth = cfg.yubikey;
        };
        u2f = mkIf cfg.yubikey {
          enable = true;
          control = "sufficient";
          settings = {
            debug = false;
            interactive = true;
            cue = true;
            origin = "pam://yubi";
            authfile = "/etc/u2f_mappings";
            max_devices = 5;
          };
        };
      };

      # Polkit for privilege elevation
      polkit.enable = true;
    };

    # GNOME Keyring for credential storage (NixOS)
    services.gnome.gnome-keyring.enable = mkIf isLinux true;

    # GPG agent configuration (NixOS)
    programs.gnupg.agent = mkIf (isLinux && cfg.gpg) {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = mkDefault pkgs.pinentry-qt;
    };

    # Firewall configuration (NixOS)
    networking.firewall = mkIf (isLinux && cfg.firewall) {
      enable = true;
      # Add firewall rules as needed
    };

    # System-level security packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      with pkgs;
      optionals cfg.yubikey [
        yubikey-manager
        yubikey-personalization
        yubioath-flutter # GUI tool (replaces yubikey-manager-qt)
      ]
      ++ optionals cfg.gpg [
        gnupg
        pinentry-qt
      ]
    );

    # User groups for security hardware access (NixOS)
    users.users.${config.host.username}.extraGroups = mkIf isLinux (
      optional cfg.yubikey "uucp" # YubiKey access
    );

    # Assertions
    assertions = [
      {
        assertion = cfg.firewall -> isLinux;
        message = "Advanced firewall configuration is only available on NixOS";
      }
    ];
  };
}
