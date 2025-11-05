# Integration tests for NixOS configurations
# Run with: nix build .#checks.x86_64-linux.<test-name>
{
  pkgs,
  lib,
  ...
}:
let
  # Helper to create a basic test
  mkTest = import "${pkgs.path}/nixos/tests/make-test-python.nix";

  # Common test machine configuration
  mkTestMachine =
    hostFeatures:
    { ... }:
    {
      imports = [
        ../modules/shared
        ../modules/nixos
      ];

      # Minimal boot config for VMs
      boot.loader.grub.enable = false;
      boot.loader.systemd-boot.enable = lib.mkForce false;
      fileSystems."/" = {
        device = "/dev/vda";
        fsType = "ext4";
      };

      # Test host configuration
      config.host = {
        username = "testuser";
        useremail = "test@example.com";
        hostname = "test-machine";
        features = hostFeatures;
      };

      # Disable services that don't work in VMs
      services.xserver.enable = lib.mkForce false;
      virtualisation.graphics = false;
    };
in
{
  # Basic boot test - ensures system can boot
  basic-boot = mkTest {
    name = "basic-boot-test";

    nodes.machine = mkTestMachine {
      development.enable = false;
      gaming.enable = false;
      desktop.enable = false;
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")
      machine.succeed("systemctl is-system-running --wait")
    '';
  };

  # User environment test - development features
  development = mkTest {
    name = "development-test";

    nodes.machine = mkTestMachine {
      development = {
        enable = true;
        rust = true;
        python = true;
        node = true;
      };
    };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      # Check user exists
      machine.succeed("id testuser")

      # Check basic tools
      machine.succeed("su - testuser -c 'which git'")
      machine.succeed("su - testuser -c 'which nix'")

      # Check development tools
      machine.succeed("su - testuser -c 'rustc --version'")
      machine.succeed("su - testuser -c 'python3 --version'")
      machine.succeed("su - testuser -c 'node --version'")
    '';
  };

  # Nix configuration test
  nix-config = mkTest {
    name = "nix-config-test";

    nodes.machine = mkTestMachine { };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      # Check experimental features
      machine.succeed("nix --version")
      machine.succeed("nix flake --version")

      # Check trusted users
      machine.succeed("grep -q 'trusted-users.*testuser' /etc/nix/nix.conf")

      # Check experimental features enabled
      machine.succeed("grep -q 'experimental-features.*flakes' /etc/nix/nix.conf")
    '';
  };
}
