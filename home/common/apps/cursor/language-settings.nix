# Language-Specific Settings for Cursor/VSCode
# Comprehensive language server configurations and per-language formatters
# Organized by language category for better maintainability

{ lib, ... }:
let
  standards = import ../../development/language-standards.nix;

  # Map simple formatter names to VSCode extension IDs
  formatterMap = {
    biome = "biomejs.biome";
    black = "ms-python.black-formatter";
    rustfmt = "rust-lang.rust-analyzer";
    "nixpkgs-fmt" = "jnoortheen.nix-ide";
    goimports = "golang.go"; # Assuming goimports is the standard
  };

  # Generate per-language formatter settings from the standards file
  perLanguageFormatters =
    lib.attrsets.genAttrs
      [
        "javascript"
        "javascriptreact"
        "typescript"
        "typescriptreact"
        "json"
        "jsonc"
        "css"
        "graphql"
        "python"
        "rust"
        "nix"
      ]
      (
        lang:
        let
          # Determine the base language standard (e.g., 'javascriptreact' uses 'javascript')
          standardName =
            {
              javascriptreact = "javascript";
              typescriptreact = "typescript";
              jsonc = "json";
            }
            .${lang} or lang;

          standard = standards.languages.${standardName} or { };
          formatterId =
            if standard ? formatter && standard.formatter != null then
              formatterMap.${standard.formatter} or null
            else
              null;
        in
        lib.optionalAttrs (formatterId != null) {
          "editor.defaultFormatter" = formatterId;
          "editor.tabSize" = standard.indent or 2;
          "editor.insertSpaces" = true;

          "editor.codeActionsOnSave" =
            if standard.formatter == "biome" then
              {
                "source.fixAll.biome" = "explicit";
                "source.organizeImports.biome" = "explicit";
              }
            else if lang == "python" then
              { "source.organizeImports" = "explicit"; }
            else if lang == "go" then
              { "source.organizeImports" = "explicit"; }
            else if lang == "rust" then
              { "source.fixAll" = "explicit"; }
            else
              { };
        }
      );

  # Shared settings for TypeScript & JavaScript
  jsTsShared = {
    ".preferences.quoteStyle" = "double";
    ".suggest.autoImports" = true;
    ".updateImportsOnFileMove.enabled" = "always";
    ".inlayHints.enabled" = "on";
    ".preferences.includePackageJsonAutoImports" = "auto";
    ".workspaceSymbols.scope" = "allOpenProjects";
  };

  # Helper to add a prefix to attribute set keys
  prefixKeys =
    prefix: attrs:
    builtins.listToAttrs (
      builtins.map (name: {
        name = "${prefix}${name}";
        value = attrs.${name};
      }) (builtins.attrNames attrs)
    );

in
{
  userSettings = lib.mkMerge [
    (prefixKeys "javascript" jsTsShared)
    (prefixKeys "typescript" jsTsShared)
    perLanguageFormatters
    {
      # ==== PYTHON ECOSYSTEM ====
      "python.analysis.typeCheckingMode" = "strict";
      "python.analysis.autoImportCompletions" = true;
      "python.analysis.diagnosticMode" = "workspace";
      "python.testing.pytestEnabled" = true;

      # ==== GO ECOSYSTEM ====
      "go.useLanguageServer" = true;
      "go.lintTool" = "golangci-lint";
      "gopls".ui.semanticTokens = true;

      # ==== RUST ECOSYSTEM ====
      "rust-analyzer.check.command" = "clippy";

      # ==== NIX ECOSYSTEM ====
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings".nil.formatting.command = [ "nixfmt" ];

      # ==== BIOME CONFIGURATION ====
      "biome.enabled" = true;

      # ==== MISC ====
      "shellcheck.enableQuickFix" = true;
      "files.associations" = {
        ".bashrc" = "shellscript";
        ".zshrc" = "shellscript";
      };

      "[yaml]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
      };
      "[toml]" = {
        "editor.insertSpaces" = true;
        "editor.tabSize" = 2;
      };
    }
  ];
}
