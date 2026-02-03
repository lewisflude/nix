# Helix editor configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.helix
{ config, ... }:
let
  # Language standards - inline for dendritic pattern
  languageStandards = {
    nix = { lsp = "nixd"; formatter = "nixfmt"; indent = 2; };
    typescript = { lsp = "vtsls"; formatter = "biome"; indent = 2; fileTypes = [ "ts" "tsx" ]; };
    javascript = { lsp = "vtsls"; formatter = "biome"; indent = 2; fileTypes = [ "js" "jsx" ]; };
    json = { lsp = "vscode-langservers-extracted"; formatter = "biome"; indent = 2; fileTypes = [ "json" "jsonc" ]; };
    css = { lsp = "vscode-langservers-extracted"; formatter = "biome"; indent = 2; fileTypes = [ "css" "scss" ]; };
    graphql = { lsp = "graphql-language-server"; formatter = "biome"; indent = 2; fileTypes = [ "graphql" "gql" ]; };
    python = { lsp = "pyright"; formatter = "ruff"; indent = 4; unit = "    "; fileTypes = [ "py" ]; };
    go = { lsp = "gopls"; formatter = "gofumpt"; indent = 4; unit = "    "; fileTypes = [ "go" ]; };
    rust = { lsp = "rust-analyzer"; formatter = "rustfmt"; indent = 4; unit = "    "; fileTypes = [ "rs" ]; };
    cpp = { lsp = "clangd"; formatter = "clang-format"; indent = 4; unit = "    "; fileTypes = [ "cpp" "cxx" "cc" "hpp" "hxx" "h" ]; };
    yaml = { lsp = "yaml-language-server"; formatter = "yamlfmt"; formatterArgs = [ "-" ]; indent = 2; fileTypes = [ "yaml" "yml" ]; };
    toml = { lsp = "taplo"; formatter = "taplo"; indent = 2; fileTypes = [ "toml" ]; };
  };
in
{
  flake.modules.homeManager.helix = { lib, pkgs, config, ... }:
    let
      getLanguageFilename = name: value:
        let
          extension = if (value ? fileTypes && builtins.length value.fileTypes > 0)
                      then builtins.head value.fileTypes
                      else name;
          extensionMap = { javascript = "js"; typescript = "ts"; jsx = "jsx"; tsx = "tsx"; };
        in "file.${extensionMap.${name} or extension}";

      buildFormatter = name: value:
        let
          isBiome = value.formatter == "biome";
          baseArgs = lib.optionals isBiome [ "format" "--stdin-file-path" (getLanguageFilename name value) ];
          extraArgs = value.formatterArgs or [ ];
        in { command = value.formatter; args = baseArgs ++ extraArgs; };

      lspPackages = [
        pkgs.nixd
        pkgs.nodePackages.typescript-language-server
        pkgs.vscode-langservers-extracted
        pkgs.yaml-language-server
        pkgs.taplo
        pkgs.gopls
        pkgs.rust-analyzer
        pkgs.pyright
        pkgs.llvmPackages.clang-unwrapped
      ];

      formatterPackages = [
        pkgs.nixfmt
        pkgs.biome
        pkgs.yamlfmt
        pkgs.gotools
        pkgs.clang-tools
        pkgs.black
        pkgs.rustfmt
        pkgs.ripgrep
        pkgs.fd
      ];
    in
    {
      programs.helix = {
        enable = true;
        extraPackages = lspPackages ++ formatterPackages;
        languages = {
          language = lib.mapAttrsToList (name: value: {
            inherit name;
            scope = "source.${name}";
            injection-regex = name;
            file-types = value.fileTypes or [ name ];
            language-servers = if value.formatter == "biome" then [ value.lsp "biome" ] else [ value.lsp ];
            indent = {
              tab-width = value.indent;
              unit = value.unit or (lib.concatStrings (lib.replicate value.indent " "));
            };
            auto-format = value.formatter != null;
          } // lib.optionalAttrs (value ? comment) { comment-tokens = [ value.comment ]; }
            // lib.optionalAttrs (value.formatter != null) { formatter = buildFormatter name value; }
          ) languageStandards;

          language-server = {
            biome = { command = "biome"; args = [ "lsp-proxy" ]; };
          };
        };

        settings = {
          editor = {
            line-number = "relative";
            cursorline = true;
            bufferline = "multiple";
            true-color = true;
            undercurl = true;
            color-modes = true;
            scrolloff = 8;
            rulers = [ 80 120 ];
            completion-trigger-len = 1;
            idle-timeout = 50;
            middle-click-paste = true;
            end-of-line-diagnostics = "hint";
            soft-wrap.enable = true;
          };
          editor.cursor-shape = { insert = "bar"; normal = "block"; select = "underline"; };
          editor.indent-guides = { render = true; character = "╎"; };
          editor.inline-diagnostics = { cursor-line = "error"; other-lines = "disable"; };
          editor.lsp = { display-messages = true; display-inlay-hints = true; auto-signature-help = false; };
          editor.statusline = {
            left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
            center = [ ];
            right = [ "diagnostics" "selections" "position" "file-encoding" "file-type" ];
            mode = { normal = "NORMAL"; insert = "INSERT"; select = "SELECT"; };
          };
          editor.whitespace = {
            render = { space = "none"; tab = "all"; newline = "none"; };
            characters = { tab = "→"; tabpad = " "; };
          };
          editor.file-picker = { hidden = false; parents = true; ignore = true; git-ignore = true; };
          keys.normal = {
            space = { space = "file_picker"; w = ":w"; q = ":q"; };
            "A-," = "goto_previous_buffer";
            "A-." = "goto_next_buffer";
            "A-w" = ":buffer-close";
            "A-/" = "repeat_last_motion";
            "C-," = ":config-open";
            esc = [ "collapse_selection" "keep_primary_selection" ];
          };
          keys.insert = { j = { k = "normal_mode"; }; };
        };
      };

      home.file.".config/helix/runtime/.keep".text = "";
    };
}
