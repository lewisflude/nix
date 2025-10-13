{lib}: {
  # Validate that import patterns follow the standard
  # Directories without .nix, files with .nix
  validateImportPatterns = imports: let
    invalidImports = lib.filter (import:
      if lib.hasSuffix ".nix" import
      then false # Files with .nix are valid
      else if lib.hasInfix "/" import
      then
        # Check if it's a directory or file
        # This is a compile-time check, so we can't actually check the filesystem
        # Instead, we'll warn about potential issues
        true
      else true)
    imports;
  in
    if invalidImports != []
    then lib.warn "Potentially invalid import patterns found: ${lib.concatStringsSep ", " invalidImports}" true
    else true;

  # Check for common configuration issues
  validateModuleStructure = module: let
    hasOptions = module ? options;
    hasConfig = module ? config;
    hasImports = module ? imports;
  in {
    valid = hasOptions || hasConfig || hasImports;
    warnings =
      lib.optional (!hasOptions && !hasConfig && !hasImports) "Module appears to be empty";
  };

  # Validate feature flag usage
  validateFeatures = config: let
    features = config.features or {};
    enabledFeatures = lib.filterAttrs (_name: feat: feat.enable or false) features;
  in {
    total = lib.length (lib.attrNames features);
    enabled = lib.length (lib.attrNames enabledFeatures);
    disabled = (lib.length (lib.attrNames features)) - (lib.length (lib.attrNames enabledFeatures));
  };

  # Assert platform compatibility
  assertPlatform = {
    system,
    supported,
    moduleName,
  }:
    assert lib.assertMsg
    (lib.elem system supported)
    "Module '${moduleName}' is not supported on ${system}. Supported platforms: ${lib.concatStringsSep ", " supported}"; true;

  # Check for circular dependencies (basic check)
  checkCircularDeps = imports: let
    # This is a simplified check - a full implementation would require
    # recursive traversal of all imports
    duplicates = lib.filter (x: (lib.count (y: x == y) imports) > 1) imports;
  in
    if duplicates != []
    then lib.warn "Potential circular dependency detected with: ${lib.concatStringsSep ", " duplicates}" true
    else true;

  # Validate overlay structure
  validateOverlay = overlay: let
    # Check that overlay is a function that takes final and prev
    isFunction = lib.isFunction overlay;
  in {
    valid = isFunction;
    warnings = lib.optional (!isFunction) "Overlay should be a function taking 'final' and 'prev' arguments";
  };

  # Create a validation report
  mkValidationReport = {
    config,
    checks ? [],
  }: let
    featureValidation = validateFeatures config;
    allChecks =
      checks
      ++ [
        {
          name = "Feature Configuration";
          status =
            if featureValidation.total > 0
            then "pass"
            else "info";
          message = "Total features: ${toString featureValidation.total}, Enabled: ${toString featureValidation.enabled}, Disabled: ${toString featureValidation.disabled}";
        }
      ];
    passed = lib.filter (c: c.status == "pass") allChecks;
    failed = lib.filter (c: c.status == "fail") allChecks;
    warnings = lib.filter (c: c.status == "warn") allChecks;
  in {
    inherit allChecks passed failed warnings;
    summary = {
      total = lib.length allChecks;
      passed = lib.length passed;
      failed = lib.length failed;
      warnings = lib.length warnings;
    };
    success = (lib.length failed) == 0;
  };

  # Helper to create assertion checks
  mkCheck = {
    name,
    assertion,
    message,
    severity ? "fail", # "fail", "warn", or "info"
  }: {
    inherit name message;
    status =
      if assertion
      then "pass"
      else severity;
  };

  # Validate host configuration
  validateHostConfig = hostConfig: let
    requiredFields = ["username" "useremail" "system" "hostname"];
    hasAllFields = lib.all (field: hostConfig ? ${field}) requiredFields;
    missingFields = lib.filter (field: !(hostConfig ? ${field})) requiredFields;
  in
    mkCheck {
      name = "Host Configuration";
      assertion = hasAllFields;
      message =
        if hasAllFields
        then "All required fields present"
        else "Missing required fields: ${lib.concatStringsSep ", " missingFields}";
    };

  # Validate secrets configuration
  validateSecretsConfig = config: let
    hasSops = config ? sops;
    hasSecrets = hasSops && (config.sops ? secrets);
  in
    mkCheck {
      name = "Secrets Configuration";
      assertion = !hasSops || hasSecrets;
      message =
        if !hasSops
        then "SOPS not configured"
        else if hasSecrets
        then "SOPS properly configured"
        else "SOPS enabled but no secrets defined";
      severity = "warn";
    };
}
