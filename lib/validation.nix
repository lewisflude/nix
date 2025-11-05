{ lib }:
rec {
  # Assert platform compatibility
  assertPlatform =
    {
      system,
      supported,
      moduleName,
    }:
    assert lib.assertMsg (lib.elem system supported)
      "Module '${moduleName}' is not supported on ${system}. Supported platforms: ${lib.concatStringsSep ", " supported}";
    true;

  # Helper to create assertion checks
  mkCheck =
    {
      name,
      assertion,
      message,
      severity ? "fail", # "fail", "warn", or "info"
    }:
    {
      inherit name message;
      status = if assertion then "pass" else severity;
    };

  # Validate host configuration
  validateHostConfig =
    hostConfig:
    let
      requiredFields = [
        "username"
        "useremail"
        "system"
        "hostname"
      ];
      hasAllFields = lib.all (field: lib.hasAttr field hostConfig) requiredFields;
      missingFields = lib.filter (field: !(lib.hasAttr field hostConfig)) requiredFields;
    in
    mkCheck {
      name = "Host Configuration";
      assertion = hasAllFields;
      message =
        if hasAllFields then
          "All required fields present"
        else
          "Missing required fields: ${lib.concatStringsSep ", " missingFields}";
    };

  # Validate secrets configuration
  validateSecretsConfig =
    config:
    let
      hasSops = config ? sops;
      hasSecrets = hasSops && (config.sops ? secrets);
    in
    mkCheck {
      name = "Secrets Configuration";
      assertion = !hasSops || hasSecrets;
      message =
        if !hasSops then
          "SOPS not configured"
        else if hasSecrets then
          "SOPS properly configured"
        else
          "SOPS enabled but no secrets defined";
      severity = "warn";
    };
}
