# Validation functions for configuration values
# Centralize common validation patterns and assertion helpers
{ lib }:
rec {
  # Port validation
  isValidPort = port: lib.isInt port && port >= 1 && port <= 65535;

  # Path validation
  pathExists = path: builtins.pathExists (toString path);

  # Username validation (POSIX compliant)
  # Must start with lowercase letter or underscore
  # Can contain lowercase letters, numbers, underscores, and hyphens
  isValidUsername = name: builtins.match "[a-z_][a-z0-9_-]*[$]?" name != null;

  # Email validation (basic format check)
  isValidEmail = email: builtins.match "[^@]+@[^@]+\\.[^@]+" email != null;

  # IP address validation (basic IPv4)
  isValidIPv4 = ip: builtins.match "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}" ip != null;

  # URL validation (basic format)
  isValidURL = url: builtins.match "(https?|ftp)://[^\\s]+" url != null;

  # Directory path validation (must be absolute and exist)
  isValidDirectory = path: lib.hasPrefix "/" (toString path) && pathExists path;

  # File path validation (must be absolute and exist)
  isValidFile = path: lib.hasPrefix "/" (toString path) && pathExists path;

  # Timezone validation (checks if valid format, not exhaustive)
  isValidTimezone = tz: builtins.match "[A-Z][a-zA-Z_]+/[A-Z][a-zA-Z_]+" tz != null;

  # Version string validation (semantic versioning)
  isValidVersion = version: builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" version != null;

  # Helper to create assertions with consistent formatting
  mkAssertion = condition: message: {
    assertion = condition;
    inherit message;
  };

  # Create assertion with detailed error message
  mkDetailedAssertion =
    {
      condition,
      expected,
      got,
      solution ? null,
    }:
    {
      assertion = condition;
      message = ''
        Configuration Error:

        Expected: ${expected}
        Got: ${toString got}
        ${lib.optionalString (solution != null) "Solution: ${solution}"}
      '';
    };

  # Validate port with assertion
  assertValidPort =
    port: name:
    mkAssertion (isValidPort port) "${name}: Invalid port ${toString port}. Must be between 1 and 65535.";

  # Validate path exists with assertion
  assertPathExists =
    path: name: mkAssertion (pathExists path) "${name}: Path does not exist: ${toString path}";

  # Validate username with assertion
  assertValidUsername =
    username:
    mkAssertion (isValidUsername username) "Invalid username '${username}'. Must start with lowercase letter or underscore, contain only lowercase letters, numbers, underscores, and hyphens.";

  # Validate email with assertion
  assertValidEmail = email: mkAssertion (isValidEmail email) "Invalid email format: ${email}";

  # Validate non-empty string
  isNonEmptyString = str: lib.isString str && str != "";

  # Validate non-empty list
  isNonEmptyList = list: lib.isList list && list != [ ];

  # Validate attribute set is not empty
  isNonEmptyAttrs = attrs: lib.isAttrs attrs && attrs != { };

  # Validate UID/GID range (typically 1000-65535 for user accounts)
  isValidUID = uid: lib.isInt uid && uid >= 1000 && uid <= 65535;

  isValidSystemUID = uid: lib.isInt uid && uid >= 1 && uid <= 999;

  # Validate mode (octal file permissions as string)
  isValidMode = mode: builtins.match "0[0-7]{3}" mode != null;

  # Combine multiple assertions
  mkAssertions = assertions: builtins.filter (a: !a.assertion) assertions;

  # Check if all validations pass
  allValid = validators: builtins.all (v: v) validators;

  # Helper to validate required fields in an attrset
  hasRequiredFields =
    attrset: requiredFields: builtins.all (field: attrset ? ${field}) requiredFields;

  assertRequiredFields =
    attrset: requiredFields: name:
    let
      missingFields = builtins.filter (field: !(attrset ? ${field})) requiredFields;
    in
    mkAssertion (
      missingFields == [ ]
    ) "${name}: Missing required fields: ${lib.concatStringsSep ", " missingFields}";
}
