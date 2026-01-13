{
  mkTest,
  mkTestMachine,
}:
mkTest {
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
}
