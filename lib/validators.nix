# Simplified validation functions
# Only includes validators that are actually useful for Nix module configuration
{ lib }:
{
  # Port validation - actually useful for service configuration
  isValidPort = port: lib.isInt port && port >= 1 && port <= 65535;

  # Assertion helper - creates standard assertion format
  mkAssertion = condition: message: {
    assertion = condition;
    inherit message;
  };

  # Validate port with assertion - useful for service modules
  assertValidPort = port: name:
    {
      assertion = lib.isInt port && port >= 1 && port <= 65535;
      message = "${name}: Invalid port ${toString port}. Must be between 1 and 65535.";
    };
}
