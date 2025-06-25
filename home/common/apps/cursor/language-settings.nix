{ lib, ... }:

let
  standards     = import ../../development/language-standards.nix;
  formatterMap  = {
    biome       = "biomejs.biome";
    black       = "ms-python.black-formatter";
    rustfmt     = "rust-lang.rust-analyzer";
    nixfmt      = "jnoortheen.nix-ide";
    goimports   = "golang.go";
    yamlfmt     = "redhat.vscode-yaml";
    taplo       = "tamasfe.even-better-toml";
  };

  languages = [
    "javascript" "javascriptreact" "typescript" "typescriptreact"
    "json"       "jsonc"          "css"        "graphql"
    "python"     "rust"           "nix"        "yaml"         "toml"
  ];

  entries = lib.filter (e: e != null) (
    lib.map (lang:
      let
        aliasMap = {
          javascriptreact = "javascript";
          typescriptreact = "typescript";
          jsonc           = "json";
        };
        stdName = aliasMap.${lang} or lang;
        std     = standards.languages.${stdName} or {};
      in if std?formatter then {
        name = "[${lang}]";
        value = lib.filterAttrs (_: v: v != null) {
          "editor.defaultFormatter"  = formatterMap.${std.formatter};
          "editor.insertSpaces"      = true;
          "editor.tabSize"           = std.indent or 2;
          "editor.codeActionsOnSave" = if std.formatter == "biome" then {
            "source.fixAll.biome"        = "explicit";
            "source.organizeImports.biome" = "explicit";
          } else null;
        };
      } else null
    ) languages
  );

  perLanguageFormatters = builtins.listToAttrs entries;

in
{
  userSettings = lib.mkMerge [
    perLanguageFormatters

    {
      python.analysis.typeCheckingMode     = "strict";
      python.analysis.autoImportCompletions = true;
      python.analysis.diagnosticMode       = "workspace";
      python.testing.pytestEnabled         = true;

      go.useLanguageServer     = true;
      go.lintTool              = "golangci-lint";
      gopls.ui.semanticTokens  = true;

      rust-analyzer.check.command = "clippy";

      nix.enableLanguageServer = true;
      nix.serverPath           = "nil";
      nix.serverSettings.nil.formatting.command = [ "nixfmt" ];

      biome.enabled = true;

      shellcheck.enableQuickFix = true;
      files.associations = {
        ".bashrc" = "shellscript";
        ".zshrc"  = "shellscript";
      };

    }
  ];
}