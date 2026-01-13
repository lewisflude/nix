{
  pkgs,
  # lib,
  ...
}:
let
  helpers = import ./lib/test-helpers.nix { inherit pkgs; };
  inherit (helpers) mkTest mkTestMachine;
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

  # Feature tests
  development = import ./features/development.nix { inherit mkTest mkTestMachine; };
  gaming = import ./features/gaming.nix { inherit mkTest mkTestMachine; };
}
