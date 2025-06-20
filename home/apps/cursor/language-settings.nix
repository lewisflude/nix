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
    "python.defaultInterpreterPath" = "python3";
    "python.analysis.typeCheckingMode" = "basic";

    # Go
    "go.formatTool" = "goimports";
    "go.lintTool" = "golangci-lint";
    "go.useLanguageServer" = true;

    # Rust
    "rust-analyzer.checkOnSave.command" = "clippy";
    "rust-analyzer.cargo.features" = "all";

    # Biome Configuration (JavaScript/TypeScript)
    "biomejs.enable" = true;
    "biomejs.lspBin" = "biome";
    "biomejs.rename" = true;
    "biomejs.requireConfigFile" = false;

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
  };
}
