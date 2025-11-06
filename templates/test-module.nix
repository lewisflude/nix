_: {
  name = "test-FEATURE_NAME";

  nodes = {
    machine =
      { ... }:
      {
        imports = [
          ../modules/shared/host-options.nix
          ../modules/CATEGORY/features/FEATURE_NAME.nix
        ];

        host = {
          username = "testuser";
          hostname = "test-machine";
          features.FEATURE_NAME = {
            enable = true;

          };
        };
      };
  };

  testScript = ''

    machine.wait_for_unit("multi-user.target")


    machine.succeed("which example-command")


    machine.wait_for_unit("example-service.service")
    machine.succeed("systemctl status example-service.service")


    machine.succeed("test -f /etc/example/config.yaml")


    machine.succeed("example-command --version")
    output = machine.succeed("example-command --test")
    assert "expected output" in output, f"Unexpected output: {output}"


    machine.succeed("groups testuser | grep example-group")


    machine.wait_for_open_port(8080)
    machine.succeed("curl -f http://localhost:8080/health")

    print("✓ All tests passed")
  '';
}
