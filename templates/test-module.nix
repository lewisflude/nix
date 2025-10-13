# Test module template
# For testing feature modules and configurations
# Place in tests/ directory
{
  lib,
  pkgs,
  ...
}: {
  name = "test-FEATURE_NAME";
  
  # Test that verifies the feature works correctly
  nodes = {
    machine = {
      config,
      pkgs,
      ...
    }: {
      imports = [
        ../modules/shared/host-options.nix
        ../modules/CATEGORY/features/FEATURE_NAME.nix
      ];
      
      # Enable the feature
      host = {
        username = "testuser";
        hostname = "test-machine";
        features.FEATURE_NAME = {
          enable = true;
          # Additional test-specific options
        };
      };
    };
  };
  
  testScript = ''
    # Wait for the machine to boot
    machine.wait_for_unit("multi-user.target")
    
    # Test 1: Check that required packages are installed
    machine.succeed("which example-command")
    
    # Test 2: Verify service is running (if applicable)
    machine.wait_for_unit("example-service.service")
    machine.succeed("systemctl status example-service.service")
    
    # Test 3: Check configuration file exists
    machine.succeed("test -f /etc/example/config.yaml")
    
    # Test 4: Verify functionality
    machine.succeed("example-command --version")
    output = machine.succeed("example-command --test")
    assert "expected output" in output, f"Unexpected output: {output}"
    
    # Test 5: Check user groups
    machine.succeed("groups testuser | grep example-group")
    
    # Test 6: Verify network access (if applicable)
    machine.wait_for_open_port(8080)
    machine.succeed("curl -f http://localhost:8080/health")
    
    print("✓ All tests passed")
  '';
}
