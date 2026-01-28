{
  lib,
  pkgs,
  config,
  inputs,
  constants,
  ...
}:
{

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
  users = {
    users.${config.host.username} = {
      home = "/Users/${config.host.username}";
      openssh.authorizedKeys.keys = [
        # Mercury MacBook (ED25519)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyBDIzK/OoFY7M1i96wP9wE+OeKk56iTvPwStEiFc+k lewis@lewisflude.com"
        # iPhone Termux (ED25519)
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuc2y4LO/GMf02/as8OqUB+zKl+sU44umYXNVC7KzF9 termix@phone"
        # iPhone Prompt 3 with Secure Enclave (hardware-backed, very secure)
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBL9zRrDvYpeH9zmtzNEMbMaML1mZOilWZbWfHtwDP0cn36PO0lyuRqsKYlrgmCrTdGkh34gk2hQvI4HMeGf2Bxs="
      ];
      shell = pkgs.zsh;
    };
  };

  # Create wheel group and add user to it for sops-nix secrets access
  users.knownGroups = [ "wheel" ];
  users.groups.wheel.gid = 0; # wheel is traditionally GID 0

  # Add user to wheel group via system activation script
  system.activationScripts.addUserToWheel.text = ''
    if ! dscl . -read /Groups/wheel GroupMembership 2>/dev/null | grep -q "${config.host.username}"; then
      echo "Adding ${config.host.username} to wheel group..."
      dseditgroup -o edit -a ${config.host.username} -t user wheel
    fi
  '';
  time.timeZone = constants.defaults.timezone;

  # YubiKey touch notifications - visual and audio feedback on macOS
  # Provides system sounds when YubiKey awaits physical touch for GPG/SSH operations
  # See: https://github.com/reo101/yknotify-rs
  #
  # DISABLED: Upstream flake has build issues - missing macOS frameworks in buildInputs
  # The package fails to build because mac-notification-sys can't find Cocoa/Foundation frameworks
  # Issue: https://github.com/reo101/yknotify-rs/issues (needs to add darwin.apple_sdk.frameworks)
  #
  # Alternative: Manual install with Go version (works out of the box)
  #   go install github.com/noperator/yknotify@latest
  #   yknotify  # Run when you want visual feedback
  #
  # services.yknotify-rs = {
  #   enable = true;
  #   requestSound = "Tink";
  #   dismissedSound = "Pop";
  # };

  # Disabled: SOPS password file not available, causing service failures
  # host.features.restic = {
  #   enable = true;
  #   backups.macbook-home = {
  #     enable = true;
  #     path = "/Users/${config.host.username}/.config/nix";
  #     # Use IPv4 address to avoid IPv6 connectivity issues
  #     repository = "rest:http://${constants.hosts.jupiter.ipv4}:8000/macos-${config.host.hostname}";
  #     passwordFile = config.sops.secrets.restic-password.path;
  #     timer = "daily";
  #     user = config.host.username;
  #     initialize = false;
  #     createWrapper = false;
  #   };
  # };
}
