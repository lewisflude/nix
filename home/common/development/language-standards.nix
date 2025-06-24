{
  # Unified Language Standards
  # This file is the single source of truth for language-specific configurations.
  # Editors like Helix and Cursor should source their settings from here to ensure
  # consistency and simplify maintenance.

  languages = {
    # Nix
    nix = {
      lsp = "nil";
      formatter = "nixpkgs-fmt";
      indent = 2;
      comment = "#";
    };

    # Web (Biome)
    typescript = {
      lsp = "typescript-language-server";
      formatter = "biome";
      indent = 2;
      comment = "//";
      fileTypes = [
        "ts"
        "tsx"
      ];
    };
    javascript = {
      lsp = "typescript-language-server";
      formatter = "biome";
      indent = 2;
      comment = "//";
      fileTypes = [
        "js"
        "jsx"
      ];
    };
    json = {
      lsp = "vscode-langservers-extracted";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "json" ];
    };
    css = {
      lsp = "vscode-langservers-extracted";
      formatter = "biome";
      indent = 2;
      comment = "/*";
      fileTypes = [ "css" ];
    };
    graphql = {
      lsp = "graphql-language-server";
      formatter = "biome";
      indent = 2;
      comment = "#";
      fileTypes = [
        "graphql"
        "gql"
      ];
    };

    # Other
    yaml = {
      lsp = "yaml-language-server";
      formatter = null; # Biome doesn't support YAML formatting
      indent = 2;
      fileTypes = [
        "yaml"
        "yml"
      ];
    };
    markdown = {
      lsp = "marksman";
      formatter = null; # Biome doesn't support Markdown formatting
      indent = 2;
      fileTypes = [
        "md"
        "markdown"
      ];
    };

    # Systems
    rust = {
      lsp = "rust-analyzer";
      formatter = "rustfmt";
      indent = 4;
      unit = "    ";
      fileTypes = [ "rs" ];
    };
    python = {
      lsp = "pyright";
      formatter = "black";
      indent = 4;
      unit = "    ";
      fileTypes = [ "py" ];
    };
  };
}
