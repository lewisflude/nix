# Language-Specific Settings for Cursor/VSCode
# Comprehensive language server configurations and per-language formatters
# Organized by language category for better maintainability

{ ... }:
{
  userSettings = {
    # ==== TYPESCRIPT & JAVASCRIPT ECOSYSTEM ====

    # TypeScript Configuration (Enhanced)
    "typescript.preferences.quoteStyle" = "double";
    "typescript.suggest.autoImports" = true;
    "typescript.suggest.enabled" = true;
    "typescript.suggest.paths" = true;
    "typescript.suggest.includeCompletionsForModuleExports" = true;
    "typescript.updateImportsOnFileMove.enabled" = "always";
    "typescript.inlayHints.enabled" = "on";
    "typescript.inlayHints.includeInlayParameterNameHints" = "all";
    "typescript.inlayHints.includeInlayParameterNameHintsWhenArgumentMatchesName" = false;
    "typescript.inlayHints.includeInlayFunctionParameterTypeHints" = true;
    "typescript.inlayHints.includeInlayVariableTypeHints" = true;
    "typescript.inlayHints.includeInlayPropertyDeclarationTypeHints" = true;
    "typescript.inlayHints.includeInlayFunctionLikeReturnTypeHints" = true;
    "typescript.inlayHints.includeInlayEnumMemberValueHints" = true;
    "typescript.preferences.useLabelDetailsInCompletionEntries" = true;
    # Ensure Go to Definition works properly
    "typescript.preferences.includePackageJsonAutoImports" = "auto";
    "typescript.workspaceSymbols.scope" = "allOpenProjects";
    "typescript.disableAutomaticTypeAcquisition" = false;

    # JavaScript Configuration (Enhanced)
    "javascript.preferences.quoteStyle" = "double";
    "javascript.suggest.autoImports" = true;
    "javascript.suggest.enabled" = true;
    "javascript.suggest.paths" = true;
    "javascript.suggest.includeCompletionsForModuleExports" = true;
    "javascript.updateImportsOnFileMove.enabled" = "always";
    "javascript.inlayHints.enabled" = "on";
    "javascript.inlayHints.includeInlayParameterNameHints" = "all";
    "javascript.inlayHints.includeInlayParameterNameHintsWhenArgumentMatchesName" = false;
    "javascript.inlayHints.includeInlayFunctionParameterTypeHints" = true;
    "javascript.inlayHints.includeInlayVariableTypeHints" = true;
    "javascript.inlayHints.includeInlayPropertyDeclarationTypeHints" = true;
    "javascript.inlayHints.includeInlayFunctionLikeReturnTypeHints" = true;
    "javascript.inlayHints.includeInlayEnumMemberValueHints" = true;
    # Ensure Go to Definition works properly for JavaScript
    "javascript.preferences.includePackageJsonAutoImports" = "auto";
    "javascript.workspaceSymbols.scope" = "allOpenProjects";

    # ==== PYTHON ECOSYSTEM ====

    # Python Language Server (Enhanced)
    "python.analysis.typeCheckingMode" = "strict";
    "python.analysis.autoImportCompletions" = true;
    "python.analysis.autoSearchPaths" = true;
    "python.analysis.diagnosticMode" = "workspace";
    "python.analysis.stubPath" = "typings";
    "python.analysis.typeshedPaths" = [ ];
    "python.analysis.useLibraryCodeForTypes" = true;
    "python.analysis.completeFunctionParens" = true;
    "python.analysis.inlayHints.variableTypes" = true;
    "python.analysis.inlayHints.functionReturnTypes" = true;
    "python.analysis.inlayHints.callArgumentNames" = "partial";

    # Python Testing
    "python.testing.autoTestDiscoverOnSaveEnabled" = true;
    "python.testing.pytestEnabled" = true;
    "python.testing.unittestEnabled" = false;
    "python.testing.promptToConfigure" = false;

    # ==== GO ECOSYSTEM ====

    # Go Language Server (Enhanced)
    "gopls" = {
      "ui.diagnostic.staticcheck" = true;
      "ui.completion.usePlaceholders" = true;
      "ui.semanticTokens" = true;
      "ui.codelenses" = {
        "gc_details" = false;
        "generate" = true;
        "regenerate_cgo" = true;
        "test" = true;
        "tidy" = true;
        "upgrade_dependency" = true;
        "vendor" = true;
      };
      "ui.inlayhint" = {
        "assignVariableTypes" = true;
        "compositeLiteralFields" = true;
        "compositeLiteralTypes" = true;
        "constantValues" = true;
        "functionTypeParameters" = true;
        "parameterNames" = true;
        "rangeVariableTypes" = true;
      };
    };

    # Go Formatting & Imports
    "go.useLanguageServer" = true;
    "go.formatTool" = "goimports";
    "go.lintTool" = "golangci-lint";
    "go.lintOnSave" = "package";

    # ==== RUST ECOSYSTEM ====

    # Rust Analyzer (Enhanced)
    "rust-analyzer.check.command" = "clippy";
    "rust-analyzer.procMacro.enable" = true;
    "rust-analyzer.cargo.buildScripts.enable" = true;
    "rust-analyzer.diagnostics.enable" = true;
    "rust-analyzer.diagnostics.enableExperimental" = true;
    "rust-analyzer.completion.addCallArgumentSnippets" = true;
    "rust-analyzer.completion.addCallParenthesis" = true;
    "rust-analyzer.inlayHints.enable" = true;
    "rust-analyzer.inlayHints.chainingHints" = true;
    "rust-analyzer.inlayHints.parameterHints" = true;
    "rust-analyzer.inlayHints.typeHints" = true;
    "rust-analyzer.lens.enable" = true;
    "rust-analyzer.lens.methodReferences" = true;
    "rust-analyzer.lens.references" = true;

    # ==== C/C++ ECOSYSTEM ====

    # C/C++ Configuration (placeholder for when extension is available)
    # "C_Cpp.intelliSenseEngine" = "default";
    # "C_Cpp.autocomplete" = "default";
    # "C_Cpp.errorSquiggles" = "enabled";
    # "C_Cpp.dimInactiveRegions" = true;

    # ==== JAVA ECOSYSTEM ====

    # Java Configuration (placeholder for when extension is available)
    # "java.configuration.detectJdksAtStart" = true;
    # "java.compile.nullAnalysis.mode" = "automatic";
    # "java.inlayHints.parameterNames.enabled" = "all";

    # ==== NIX ECOSYSTEM ====

    # Nix Language Configuration
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "nix.serverSettings" = {
      "nil" = {
        "diagnostics" = {
          "ignored" = [
            "unused_binding"
            "unused_with"
          ];
        };
        "formatting" = {
          "command" = [ "nixfmt" ];
        };
      };
    };

    # ==== SHELL SCRIPTING ====

    # Bash/Shell Configuration
    "bashIde.globPattern" = "**/@(.bashrc|.bash_profile|.zshrc|.zprofile|*.sh|*.bash|*.zsh)";
    "shellcheck.enableQuickFix" = true;
    "shellcheck.run" = "onType";

    # ==== MARKUP & DOCUMENTATION ====

    # Markdown Configuration (Enhanced)
    "markdown.preview.breaks" = true;
    "markdown.preview.linkify" = true;
    "markdown.preview.typographer" = true;
    "markdown.extension.toc.levels" = "1..6";
    "markdown.extension.preview.autoShowPreviewToSide" = false;

    # YAML Configuration
    "yaml.completion" = true;
    "yaml.hover" = true;
    "yaml.validate" = true;
    "yaml.format.enable" = true;
    "yaml.format.singleQuote" = false;
    "yaml.format.bracketSpacing" = true;

    # JSON Configuration
    "json.validate.enable" = true;
    "json.format.enable" = true;
    "json.schemaDownload.enable" = true;

    # ==== BIOME CONFIGURATION ====

    # Biome Settings (Modern JavaScript/TypeScript Tooling)
    "biome.enabled" = true;
    "biome.lsp.bin" = "biome";
    "biome.requireConfiguration" = false;

    # ==== PER-LANGUAGE FORMATTERS ====

    # Python
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.black-formatter";
      "editor.codeActionsOnSave" = {
        "source.organizeImports" = "explicit";
      };
    };

    # Go
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
      "editor.codeActionsOnSave" = {
        "source.organizeImports" = "explicit";
      };
    };

    # Rust
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.codeActionsOnSave" = {
        "source.fixAll" = "explicit";
      };
    };

    # JavaScript & TypeScript (Biome)
    "[javascript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.codeActionsOnSave" = {
        "source.fixAll.biome" = "explicit";
        "source.organizeImports.biome" = "explicit";
      };
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.codeActionsOnSave" = {
        "source.fixAll.biome" = "explicit";
        "source.organizeImports.biome" = "explicit";
      };
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.codeActionsOnSave" = {
        "source.fixAll.biome" = "explicit";
        "source.organizeImports.biome" = "explicit";
      };
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "biomejs.biome";
      "editor.codeActionsOnSave" = {
        "source.fixAll.biome" = "explicit";
        "source.organizeImports.biome" = "explicit";
      };
    };

    # JSON & CSS (Biome)
    "[json]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[css]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[scss]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };

    # HTML & Markdown (Biome)
    "[html]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };
    "[markdown]" = {
      "editor.defaultFormatter" = "biomejs.biome";
    };

    # Nix
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
    };

    # YAML
    "[yaml]" = {
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
      "editor.autoIndent" = "advanced";
    };

    # TOML
    "[toml]" = {
      "editor.insertSpaces" = true;
      "editor.tabSize" = 2;
    };

    # ==== GLOBAL EDITOR OVERRIDES ====

    # Remove duplicate settings that were moved to settings.nix
    # Note: formatOnSave and codeActionsOnSave are handled globally in settings.nix
    # Language-specific overrides above take precedence
  };
}
