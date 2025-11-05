{lib, ...}: let
  standards = import ../../features/development/language-standards.nix;
  formatterMap = {
    biome = "biomejs.biome";
    black = "ms-python.black-formatter";
    rustfmt = "rust-lang.rust-analyzer";
    nixfmt = "jnoortheen.nix-ide";
    goimports = "golang.go";
    yamlfmt = "redhat.vscode-yaml";
    taplo = "tamasfe.even-better-toml";
    clang-format = "ms-vscode.cpptools";
  };
  baseLanguages = builtins.attrNames standards.languages;
  reactVariants = [
    "javascriptreact"
    "typescriptreact"
  ];
  jsonVariants = ["jsonc"];
  languages = baseLanguages ++ reactVariants ++ jsonVariants;
  # More efficient: use concatMap to combine map+filter in one pass
  # This avoids creating intermediate lists from separate map and filter operations
  perLanguageFormatters = lib.listToAttrs (
    lib.concatMap (
      lang: let
        aliasMap = {
          javascriptreact = "javascript";
          typescriptreact = "typescript";
          jsonc = "json";
        };
        stdName = aliasMap.${lang} or lang;
        std = standards.languages.${stdName} or {};
      in
        if std ? formatter && std.formatter != null
        then [
          {
            name = "[${lang}]";
            value = lib.filterAttrs (_: v: v != null) {
              "editor.defaultFormatter" = formatterMap.${std.formatter};
              "editor.insertSpaces" = true;
              "editor.tabSize" = std.indent or 2;
              "editor.codeActionsOnSave" =
                if std.formatter == "biome"
                then {
                  "source.fixAll.biome" = "explicit";
                  "source.organizeImports.biome" = "explicit";
                }
                else null;
            };
          }
        ]
        else []
    )
    languages
  );
in {
  userSettings = lib.mkMerge [
    perLanguageFormatters
  ];
}
