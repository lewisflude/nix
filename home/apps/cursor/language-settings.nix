# Language-Specific Settings for Cursor/VSCode
# Language server configurations and per-language formatters

{ ... }:
{
  userSettings = {
    # TypeScript/JavaScript
    "typescript.preferences.quoteStyle" = "double";
    "typescript.suggest.autoImports" = true;
    "javascript.preferences.quoteStyle" = "double";
    "typescript.updateImportsOnFileMove.enabled" = "always";
    "javascript.updateImportsOnFileMove.enabled" = "always";

    # Python
    "python.analysis.typeCheckingMode" = "strict";

    # Go
    "gopls" = {
      "ui.diagnostic.staticcheck" = true;
    };

    # Rust
    "rust-analyzer.check.command" = "clippy";
    "rust-analyzer.procMacro.enable" = true;

    # Biome Configuration (JavaScript/TypeScript)
    "biome.enabled" = true;
    "biome.lsp.bin" = "biome";
    "biome.requireConfiguration" = false;

    # Per-Language Formatters
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.black-formatter";
    };
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
    };
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[json]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[markdown]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[css]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[scss]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[html]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
    "[shellscript]" = {
      "editor.defaultFormatter" = "foxundermoon.shell-format";
    };
    "[dockerfile]" = {
      "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
    };

    "editor.formatOnSave" = true;
    "editor.codeActionsOnSave" = {
      "source.fixAll.biome" = "explicit";
      "source.organizeImports.biome" = "explicit";
    };
  };
}
