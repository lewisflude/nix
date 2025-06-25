{ lib, ... }:

let
  standards = import ../../development/language-standards.nix;
  formatterMap = {
    biome = "biomejs.biome";
    black = "ms-python.black-formatter";
    rustfmt = "rust-lang.rust-analyzer";
    "nixpkgs-fmt" = "jnoortheen.nix-ide";
    goimports = "golang.go";
  };

  languages = [
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
  ];

  perLanguageFormatters = builtins.listToAttrs (
    lib.filter
      (
        lang:
        let
          stdName =
            (
              {
                javascriptreact = "javascript";
                typescriptreact = "typescript";
                jsonc = "json";
              }
              // { }
            ).${lang} or lang;
          std = standards.languages.${stdName} or { };
        in
        std.formatter != null
      )
      (
        lib.map (
          lang:
          let
            stdName =
              (
                {
                  javascriptreact = "javascript";
                  typescriptreact = "typescript";
                  jsonc = "json";
                }
                // { }
              ).${lang} or lang;
            std = standards.languages.${stdName} or { };
            fmt = formatterMap.${std.formatter};
            cas =
              if std.formatter == "biome" then
                {
                  "source.fixAll.biome" = "explicit";
                  "source.organizeImports.biome" = "explicit";
                }
              else
                { };
          in
          {
            name = "[${lang}]";
            value = lib.filterAttrs (_: v: v != null) {
              "editor.defaultFormatter" = fmt;
              "editor.insertSpaces" = true;
              "editor.tabSize" = std.indent or 2;
              "editor.codeActionsOnSave" = if builtins.length (builtins.attrNames cas) > 0 then cas else null;
            };
          }
        ) languages
      )
  );

in
{
  userSettings = lib.mkMerge [
    perLanguageFormatters

    {
      # Python
      python.analysis.typeCheckingMode = "strict";
      python.analysis.autoImportCompletions = true;
      python.analysis.diagnosticMode = "workspace";
      python.testing.pytestEnabled = true;

      # Go
      go.useLanguageServer = true;
      go.lintTool = "golangci-lint";
      gopls.ui.semanticTokens = true;

      # Rust
      rust-analyzer.check.command = "clippy";

      # Nix
      nix.enableLanguageServer = true;
      nix.serverPath = "nil";
      nix.serverSettings.nil.formatting.command = [ "nixfmt" ];

      # Biome
      biome.enabled = true;

      # Misc
      shellcheck.enableQuickFix = true;
      files.associations = {
        ".bashrc" = "shellscript";
        ".zshrc" = "shellscript";
      };

      # Non‐formatter languages
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
