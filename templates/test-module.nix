# NixOS Test Template
# Tests are NOT flake-parts modules - they use the standard NixOS test format
# Run with: nix build .#checks.x86_64-linux.test-FEATURE_NAME
_: {
  name = "test-FEATURE_NAME";

  nodes = {
    machine = { pkgs, ... }: {
      # Import the module being tested
      imports = [
        # The test needs to import the actual NixOS module
        # In dendritic, you'd typically test the full configuration
      ];

      # Test configuration
      environment.systemPackages = [ pkgs.curl ];
    };
  };

  testScript = ''
    # Wait for system to boot
    machine.wait_for_unit("multi-user.target")

    # Check command exists
    machine.succeed("which example-command")

    # Check service is running
    machine.wait_for_unit("example-service.service")
    machine.succeed("systemctl status example-service.service")

    # Check config file exists
    machine.succeed("test -f /etc/example/config.yaml")

    # Test functionality
    machine.succeed("example-command --version")
    output = machine.succeed("example-command --test")
    assert "expected output" in output, f"Unexpected output: {output}"

    # Check network port
    machine.wait_for_open_port(8080)
    machine.succeed("curl -f http://localhost:8080/health")

    print("All tests passed")
  '';
}
