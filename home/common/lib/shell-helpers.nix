{
  lib,
  inputs,
  ...
}:
let


  # Helper: Check if a secret is available in systemConfig
  secretAvailable =
    systemConfig: name: lib.hasAttrByPath [ "sops" "secrets" name "path" ] systemConfig;

  # Helper: Get secret path from systemConfig
  secretPath = systemConfig: name: lib.attrByPath [ "sops" "secrets" name "path" ] "" systemConfig;

  # Helper: Generate shell snippet to export secret as environment variable
  secretExportSnippet =
    systemConfig: name: var:
    let
      path = secretPath systemConfig name;
    in
    lib.optionalString (secretAvailable systemConfig name) ''
      if [ -r ${lib.escapeShellArg path} ]; then
        export ${var}="$(cat ${lib.escapeShellArg path})"
      fi
    '';
in
{
  inherit
    secretAvailable
    secretPath
    secretExportSnippet
    ;
}
