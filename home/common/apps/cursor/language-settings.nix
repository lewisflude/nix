{ lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    optionalAttrs
    ;

  standards = import ../../features/development/language-standards.nix;
  formatterMap = {
    biome = "biomejs.biome";
    ruff = "charliermarsh.ruff";
    gofumpt = "golang.go";
    rustfmt = "rust-lang.rust-analyzer";
    clang-format = "ms-vscode.cpptools";
    taplo = "tamasfe.even-better-toml";
    yamlfmt = "288g.yamlfmt";
    nixfmt = "jnordberg.nix-instantiate";
    goimports = "golang.go";
    black = "ms-python.python";
  };

  # Map language variants to their standard equivalents
  aliasMap = {
    javascriptreact = "javascript";
    typescriptreact = "typescript";
    jsonc = "json";
  };

  # Build all language variants (base + react + json)
  allLanguages =
    builtins.attrNames standards.languages ++ [ "javascriptreact" "typescriptreact" "jsonc" ];

  # Build language-specific formatter config
  mkLanguageConfig =
    lang: std:
    {
      "editor.defaultFormatter" = formatterMap.${std.formatter};
      "editor.insertSpaces" = true;
      "editor.tabSize" = std.indent or 2;
    }
    // optionalAttrs (std.formatter == "biome") {
      "editor.codeActionsOnSave" = {
        "source.fixAll.biome" = "explicit";
        "source.organizeImports.biome" = "explicit";
      };
    };

  # Generate per-language settings for all languages with formatters
  perLanguageFormatters = mapAttrs' (
    lang: _:
    let
      stdName = aliasMap.${lang} or lang;
      std = standards.languages.${stdName} or { };
    in
    if std ? formatter && std.formatter != null then
      nameValuePair "[${lang}]" (mkLanguageConfig lang std)
    else
      nameValuePair "__skip_${lang}" null
  ) (lib.genAttrs allLanguages (_: { }));
in
{
  userSettings = filterAttrs (n: _: !(lib.hasPrefix "__skip_" n)) perLanguageFormatters;
}
