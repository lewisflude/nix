{
  languages = {
    # Nix: Standardized on the new RFC 166 style
    nix = {
      lsp = "nixd";
      formatter = "nixfmt";
      indent = 2;
    };

    # Web Stack: Using Biome for everything (25x faster than Prettier)
    typescript = {
      lsp = "vtsls"; # More performant than typescript-language-server
      formatter = "biome";
      indent = 2;
      fileTypes = [ "ts" "tsx" ];
    };

    javascript = {
      lsp = "vtsls";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "js" "jsx" ];
    };

    json = {
      lsp = "vscode-langservers-extracted";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "json" "jsonc" ];
    };

    css = {
      lsp = "vscode-langservers-extracted";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "css" "scss" ];
    };

    graphql = {
      lsp = "graphql-language-server";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "graphql" "gql" ];
    };

    # Python: The Ruff revolution
    python = {
      lsp = "pyright"; # Best for type-checking logic
      formatter = "ruff"; # Replaces black and isort; blazingly fast
      indent = 4;
      unit = "    ";
      fileTypes = [ "py" ];
    };

    # Go: Stricter, more idiomatic formatting
    go = {
      lsp = "gopls";
      formatter = "gofumpt"; # A stricter version of gofmt
      indent = 4;
      unit = "    ";
      fileTypes = [ "go" ];
    };

    # Rust: The Gold Standard
    rust = {
      lsp = "rust-analyzer";
      formatter = "rustfmt";
      indent = 4;
      unit = "    ";
      fileTypes = [ "rs" ];
    };

    # Systems / Config
    cpp = {
      lsp = "clangd";
      formatter = "clang-format";
      indent = 4;
      unit = "    ";
      fileTypes = [ "cpp" "cxx" "cc" "hpp" "hxx" "h" ];
    };

    yaml = {
      lsp = "yaml-language-server";
      formatter = "yamlfmt";
      formatterArgs = [ "-" ];
      indent = 2;
      fileTypes = [ "yaml" "yml" ];
    };

    toml = {
      lsp = "taplo";
      formatter = "taplo";
      indent = 2;
      fileTypes = [ "toml" ];
    };
  };
}