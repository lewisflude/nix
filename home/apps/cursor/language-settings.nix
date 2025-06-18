# Language-Specific Settings for Cursor/VSCode
# Formatters, linters, and language server configurations

{ ... }:
{
  userSettings = {
    # Global Formatter Settings
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.formatOnType" = false;
    "editor.codeActionsOnSave" = {
      "source.organizeImports" = "always";
      "source.fixAll" = "always";
      "source.fixAll.eslint" = "always";
      "source.fixAll.biome" = "always";
    };
    
    # TypeScript/JavaScript
    "typescript.preferences.quoteStyle" = "double";
    "typescript.suggest.autoImports" = true;
    "javascript.preferences.quoteStyle" = "double";
    "typescript.updateImportsOnFileMove.enabled" = "always";
    "javascript.updateImportsOnFileMove.enabled" = "always";
    
    # Python
    "python.defaultInterpreterPath" = "python3";
    "python.analysis.typeCheckingMode" = "basic";
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.black-formatter";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave" = {
        "source.organizeImports" = "always";
      };
    };
    
    # Go
    "go.formatTool" = "goimports";
    "go.lintTool" = "golangci-lint";
    "go.useLanguageServer" = true;
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
      "editor.formatOnSave" = true;
    };
    
    # Rust
    "rust-analyzer.checkOnSave.command" = "clippy";
    "rust-analyzer.cargo.features" = "all";
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
    };
    
    # Biome Configuration (JavaScript/TypeScript)
    "biomejs.enable" = true;
    "biomejs.lspBin" = "biome";
    "biomejs.rename" = true;
    "biomejs.requireConfigFile" = false;
    
    # Prettier Configuration
    "prettier.requireConfig" = false;
    "prettier.useEditorConfig" = true;
    "prettier.semi" = true;
    "prettier.singleQuote" = false;
    "prettier.tabWidth" = 2;
    "prettier.trailingComma" = "es5";
    
    # ESLint Configuration
    "eslint.validate" = [
      "javascript"
      "typescript"
      "javascriptreact"
      "typescriptreact"
      "vue"
      "svelte"
    ];
    "eslint.format.enable" = true;
    "eslint.codeActionsOnSave.mode" = "all";
    
    # File Type Formatters
    "[javascript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.formatOnSave" = true;
    };
    "[json]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[markdown]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[yaml]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[css]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[scss]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[html]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.formatOnSave" = true;
    };
    "[shellscript]" = {
      "editor.defaultFormatter" = "foxundermoon.shell-format";
      "editor.formatOnSave" = true;
    };
    "[dockerfile]" = {
      "editor.defaultFormatter" = "ms-azuretools.vscode-docker";
      "editor.formatOnSave" = true;
    };
  };
}