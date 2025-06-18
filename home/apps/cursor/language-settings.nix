# Language-Specific Settings for Cursor/VSCode
# Formatters, linters, and language server configurations

{ ... }:
{
  userSettings = {
    # TypeScript/JavaScript
    "typescript.preferences.quoteStyle" = "double";
    "typescript.suggest.autoImports" = true;
    "javascript.preferences.quoteStyle" = "double";
    
    # Python
    "python.defaultInterpreterPath" = "python3";
    "python.formatting.provider" = "black";
    "python.linting.enabled" = true;
    "python.linting.pylintEnabled" = true;
    
    # Go
    "go.formatTool" = "goimports";
    "go.lintTool" = "golangci-lint";
    "go.useLanguageServer" = true;
    
    # Rust
    "rust-analyzer.checkOnSave.command" = "clippy";
    "rust-analyzer.cargo.features" = "all";
    
    # Biome (JavaScript/TypeScript formatter)
    "biomejs.enable" = true;
    "biomejs.lspBin" = "biome";
    "biomejs.rename" = true;
    "biomejs.requireConfigFile" = false;
    
    # Prettier
    "prettier.requireConfig" = true;
    "prettier.useEditorConfig" = true;
    
    # ESLint
    "eslint.validate" = [
      "javascript"
      "typescript"
      "javascriptreact"
      "typescriptreact"
    ];
    
    # File Associations
    "[javascript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[json]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[markdown]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
    };
  };
}