{ lib, ... }:
let
  standards = import ../../features/development/language-standards.nix;
  formatterMap = {
    "nixfmt-rfc-style" = "jnordberg.nix-instantiate"; 
        "biome" = "biomejs.biome";
        "ruff" = "charliermarsh.ruff";
        "gofumpt" = "golang.go"; 
        "rustfmt" = "rust-lang.rust-analyzer";
        "clang-format" = "ms-vscode.cpptools";
        "taplo" = "tamasfe.even-better-toml";
        "yamlfmt" = "288g.yamlfmt"; 
        "nixfmt" = "jnordberg.nix-instantiate";
        "goimports" = "golang.go";
        "black" = "ms-python.python";
  };
  baseLanguages = builtins.attrNames standards.languages;
  reactVariants = [
    "javascriptreact"
    "typescriptreact"
  ];
  jsonVariants = [ "jsonc" ];
  languages = baseLanguages ++ reactVariants ++ jsonVariants;

  perLanguageFormatters = lib.listToAttrs (
    lib.concatMap (
      lang:
      let
        aliasMap = {
          javascriptreact = "javascript";
          typescriptreact = "typescript";
          jsonc = "json";
        };
        stdName = aliasMap.${lang} or lang;
        std = standards.languages.${stdName} or { };
      in
      if std ? formatter && std.formatter != null then
        [
          {
            name = "[${lang}]";
            value = lib.filterAttrs (_: v: v != null) {
              "editor.defaultFormatter" = formatterMap.${std.formatter};
              "editor.insertSpaces" = true;
              "editor.tabSize" = std.indent or 2;
              "editor.codeActionsOnSave" =
                if std.formatter == "biome" then
                  {
                    "source.fixAll.biome" = "explicit";
                    "source.organizeImports.biome" = "explicit";
                  }
                else
                  null;
            };
          }
        ]
      else
        [ ]
    ) languages
  );
in
{
  userSettings = lib.mkMerge [
    perLanguageFormatters
  ];
}
