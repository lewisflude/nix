{
  pkgs,
  lib,
  username,
  ...
}:
{
  # Add required system packages for YubiKey functionality
  environment.systemPackages = with pkgs; [
    yubioath-flutter
    yubikey-manager
    pam_u2f
    yubikey-personalization # For udev rules and user utility
  ];

  # Enable pcscd for GPG smart card support, required for GPG on YubiKey.
  services.pcscd.enable = true;
  # Add udev rules for YubiKey devices to ensure correct permissions.
  services.udev.packages = [ pkgs.yubikey-personalization ];

  security.pam = {
    sshAgentAuth.enable = true;

    # YubiKey PAM module for sudo/login authentication, based on:
    # https://joinemm.dev/blog/yubikey-nixos-guide
    u2f = {
      enable = true;
      settings = {
        # This will prompt you to insert your U2F device
        interactive = true;
        # This will prompt you to touch your U2F device
        cue = true;
        # A global origin to allow the same key to be used across machines
        origin = "pam://yubi";
        # The authorization mapping file, stored securely in the Nix store.
        # IMPORTANT: You must generate your key mappings and place them here.
        authfile = pkgs.writeText "u2f-mappings" ''
          # HOW TO GENERATE YOUR KEY MAPPING:
          # 1. Plug in your YubiKey.
          # 2. Run the command: nix-shell -p pam_u2f --run "pamu2fcfg -n -o pam://yubi"
          # 3. Touch the YubiKey when it flashes.
          # 4. A long string will be printed to your terminal. This is your key mapping.
          # 5. Prepend your username and a colon to it (e.g., "lewisflude:...")
          # 6. Replace the line below with your complete mapping string.
          # 7. Repeat for any backup keys, adding each on a new line.
          ${username}:REPLACE_WITH_YOUR_YUBIKEY_MAPPING
        '';
      };
    };

    services = {
      login = {
        u2fAuth = true;
      };
      sudo = {
        u2fAuth = true;
        sshAgentAuth = true;
      };
    };
  };
}
