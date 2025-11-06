{
  lib,
  inputs,
}:
let
  # Helper: Get catppuccin palette with fallback logic
  getPalette =
    config:
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then
      (lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then
      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else
      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";

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
    getPalette
    secretAvailable
    secretPath
    secretExportSnippet
    ;
}
