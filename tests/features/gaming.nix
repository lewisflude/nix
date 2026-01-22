{
  mkTest,
  mkTestMachine,
}:
mkTest {
  name = "gaming-feature";

  nodes.machine = mkTestMachine {
    gaming = {
      enable = true;
      steam = true;
      performance = true;
    };
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Verify Steam is installed (it might be a wrapped package)
    # Note: Steam often requires graphical environment, but we disabled X/Wayland in vm-base.
    # However, the package should still be present in path or system packages.
    machine.succeed("which steam")

    # Verify performance optimizations
    # vm.max_map_count should be 2147483642
    machine.succeed("sysctl vm.max_map_count | grep 2147483642")

    # Verify gamemode
    machine.succeed("which gamemoderun")
  '';
}
