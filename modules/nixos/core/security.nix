{
  pkgs,
  config,
  ...
}:
{
  security = {
    doas = {
      enable = true;
      extraRules = [
        {
          users = [ "lewis" ];
          keepEnv = true;
          noPass = true; # Allow passwordless privilege escalation (matches sudo config)
        }
      ];
    };
    pam = {
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "65536";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
      ];
      services = {
        login.enableGnomeKeyring = true;
        greetd.enableGnomeKeyring = true;
        niri.enableGnomeKeyring = true;
        sudo.enableGnomeKeyring = true;
        su.enableGnomeKeyring = true;
        swaylock = {
          # Custom PAM configuration for swaylock with YubiKey support
          #
          # Note: When 'text' is provided, it completely overrides auto-generated config.
          # We need this because NixOS's auto-generated config adds 'try_first_pass' to
          # the unix auth module, which prevents password prompts when u2f fails.
          #
          # Authentication flow:
          # 1. Try YubiKey (U2F) first - if present and touched, authentication succeeds
          # 2. Fall back to password authentication if YubiKey fails or is not present
          # 3. GNOME Keyring unlock (optional, for keyring integration)
          # 4. Deny access if all authentication methods fail
          #
          # This configuration ensures both YubiKey and password authentication work reliably.
          #
          # Based on research from:
          # - GitHub swaylock issue #431 (permissions issue)
          # - ArchWiki U2F documentation
          # - Yubico pam-u2f documentation (https://developers.yubico.com/pam-u2f/)
          # - NixOS Wiki Yubikey page
          # - Arch Linux PAM documentation
          text = ''
            # Account management - verify account exists and is valid
            account required ${pkgs.linux-pam}/lib/security/pam_unix.so

            # Authentication management
            # Step 1: Try YubiKey (U2F) authentication first
            # - nouserok: CRITICAL - allows password fallback if YubiKey not configured/present
            # - cue: Show prompt to touch YubiKey (swaylock will display this)
            # - userpresence=1: Require physical touch (security best practice)
            # - pinverification omitted: Uses authenticator default behavior
            auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so authfile=/etc/u2f_mappings cue nouserok userpresence=1 origin=pam://yubi

            # Step 2: Password fallback authentication
            # - sufficient: If password is correct, grant access
            # - Note: No 'try_first_pass' - ensures password prompt appears when YubiKey fails
            # - Note: No 'nullok' - enforces that users must have passwords
            auth sufficient ${pkgs.linux-pam}/lib/security/pam_unix.so

            # Step 3: GNOME Keyring unlock (optional)
            # - optional: Won't block authentication if keyring is unavailable
            auth optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

            # Step 4: Deny access if all authentication methods failed
            auth required ${pkgs.linux-pam}/lib/security/pam_deny.so

            # Password management - for password changes
            password sufficient ${pkgs.linux-pam}/lib/security/pam_unix.so yescrypt
            password optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so use_authtok

            # Session management - set up user environment
            session required ${pkgs.linux-pam}/lib/security/pam_env.so conffile=/etc/pam/environment readenv=0
            session required ${pkgs.linux-pam}/lib/security/pam_unix.so
            session required ${pkgs.linux-pam}/lib/security/pam_limits.so conf=/etc/security/limits.conf
            session optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
          '';
        };
        sudo.u2fAuth = true;
        login.u2fAuth = true;
        greetd.u2fAuth = true;
      };
      u2f = {
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
    polkit.enable = true;
  };

  # Note: speech-dispatcher (~1.67 GiB) is pulled in as a dependency
  # To exclude it, we need to find what's pulling it in and disable that instead
  # It appears as a user unit, possibly from desktop environment or accessibility features

  services.gnome.gnome-keyring.enable = true;

  systemd.tmpfiles.rules = [
    "d /run/polkit-1 0755 root root"
    "d /run/polkit-1/rules.d 0755 root root"
  ];

  systemd = {
    settings.Manager.DefaultLimitNOFILE = builtins.toString config.host.systemDefaults.fileDescriptorLimit;
    user.extraConfig = ''
      [Manager]
      DefaultLimitNOFILE=${builtins.toString config.host.systemDefaults.fileDescriptorLimit}
    '';
    user.services = {

      unlock-login-keyring = {
        description = "Unlock GNOME login keyring for auto-login sessions";
        after = [ "gnome-keyring-daemon.service" ];
        wants = [ "gnome-keyring-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.writeShellScript "unlock-keyring" ''
            sleep 2
            if ! ${pkgs.libsecret}/bin/secret-tool lookup dummy dummy 2>/dev/null; then
              printf '\n' | ${pkgs.gnome-keyring}/bin/gnome-keyring --unlock 2>/dev/null || true
            fi
          ''}";
        };
        wantedBy = [ "default.target" ];
      };
    };
  };
  environment = {
    sessionVariables = {
      XDG_RUNTIME_DIR = "/run/user/$UID";
    };
    etc."u2f_mappings" = {
      text = ''lewis:PaGbsjJa2IPXjK/nuSZEgqrqcP9JoxEO0IVVinIyfEXR0EbctKkhinM6f50ccHj7uSdy+YM2O+ToKVhqv5ynyQ==,cFyPyH4AUHDjTXelbVpfnc4DnESr8xJWyZC42DwEiofkoqQdt0lBdxPGLwjviysl7WlH+jlEw3Yhe5TBiBLNOg==,es256,+presence'';
      mode = "0644"; # Must be world-readable for non-root screen lockers like swaylock
    };
  };
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # Note: pinentry is configured via home-manager for per-user customization
      # See: home/common/features/core/gpg.nix
    };
    _1password = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      package = pkgs._1password-gui-beta;
    };
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.dbus.enable = true;
}
