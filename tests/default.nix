{
  pkgs,
  lib,
  ...
}:
let

  mkTest = import "${pkgs.path}/nixos/tests/make-test-python.nix";

  mkTestMachine =
    hostFeatures:
    { ... }:
    {
      imports = [
        ../modules/shared
        ../modules/nixos
      ];

      boot.loader.grub.enable = false;
      boot.loader.systemd-boot.enable = lib.mkForce false;
      fileSystems."/" = {
        device = "/dev/vda";
        fsType = "ext4";
      };

      config.host = {
        username = "testuser";
        useremail = "test@example.com";
        hostname = "test-machine";
        features = hostFeatures;
      };

      services.xserver.enable = lib.mkForce false;
      virtualisation.graphics = false;
    };
in
{

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


      machine.succeed("id testuser")


      machine.succeed("su - testuser -c 'which git'")
      machine.succeed("su - testuser -c 'which nix'")


      machine.succeed("su - testuser -c 'rustc --version'")
      machine.succeed("su - testuser -c 'python3 --version'")
      machine.succeed("su - testuser -c 'node --version'")
    '';
  };

  nix-config = mkTest {
    name = "nix-config-test";

    nodes.machine = mkTestMachine { };

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")


      machine.succeed("nix --version")
      machine.succeed("nix flake --version")


      machine.succeed("grep -q 'trusted-users.*testuser' /etc/nix/nix.conf")


      machine.succeed("grep -q 'experimental-features.*flakes' /etc/nix/nix.conf")
    '';
  };
}
