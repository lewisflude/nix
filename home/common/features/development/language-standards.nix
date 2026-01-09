{
  languages = {
    nix = {
      lsp = "nixd";
      formatter = "nixfmt";
      indent = 2;
    };
    typescript = {
      lsp = "typescript-language-server";
      formatter = "biome";
      indent = 2;
      fileTypes = [
        "ts"
        "tsx"
      ];
    };
    javascript = {
      lsp = "typescript-language-server";
      formatter = "biome";
      indent = 2;
      fileTypes = [
        "js"
        "jsx"
      ];
    };
    json = {
      lsp = "vscode-langservers-extracted";
      formatter = null;
      indent = 2;
      fileTypes = [ "json" ];
    };
    css = {
      lsp = "vscode-langservers-extracted";
      formatter = "biome";
      indent = 2;
      fileTypes = [ "css" ];
    };
    graphql = {
      lsp = "graphql-language-server";
      formatter = "biome";
      indent = 2;
      fileTypes = [
        "graphql"
        "gql"
      ];
    };
    yaml = {
      lsp = "yaml-language-server";
      formatter = "yamlfmt";
      indent = 2;
      fileTypes = [
        "yaml"
        "yml"
      ];
    };
    toml = {
      lsp = "taplo";
      formatter = "taplo";
      indent = 2;
      fileTypes = [ "toml" ];
    };
    markdown = {
      lsp = "marksman";
      formatter = null;
      indent = 2;
      fileTypes = [
        "md"
        "markdown"
      ];
    };
    go = {
      lsp = "gopls";
      formatter = "goimports";
      indent = 4;
      unit = "    ";
      fileTypes = [ "go" ];
    };
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
    cpp = {
      lsp = "clangd";
      formatter = "clang-format";
      indent = 4;
      unit = "    ";
      fileTypes = [
        "cpp"
        "cxx"
        "cc"
        "c++"
        "hpp"
        "hxx"
        "h"
        "hh"
      ];
    };
  };
}
