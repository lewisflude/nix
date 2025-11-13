{
  lib,
  pkgs,
  inputs,
  hostSystem,
  ...
}:
let
  standards = import ../features/development/language-standards.nix;
  makeIndentString = n: builtins.concatStringsSep "" (builtins.genList (_x: " ") n);

  # Map command names to Nix packages
  # Note: Some formatters are part of larger packages (e.g., goimports is in gotools)
  lspPackages = [
    pkgs.nixd
    pkgs.nodePackages.typescript-language-server
    pkgs.vscode-langservers-extracted
    # graphql-language-server - Not available in nixpkgs
    # GraphQL LSP support disabled until a suitable package is found or added
    pkgs.yaml-language-server
    pkgs.taplo
    pkgs.marksman
    pkgs.gopls
    pkgs.rust-analyzer
    pkgs.pyright
    pkgs.llvmPackages.clang-unwrapped # Includes clangd
  ];

  formatterPackages = [
    pkgs.nixfmt-rfc-style
    pkgs.biome
    pkgs.yamlfmt
    pkgs.gotools # Includes goimports
    pkgs.clang-tools # Includes clang-format
    pkgs.black # Python formatter
    pkgs.rustfmt # Rust formatter
    # taplo is already in lspPackages
  ];
in
{
  programs.helix = {
    enable = true;
    package = inputs.helix.packages.${hostSystem}.default; # Official Helix flake
    extraPackages = lspPackages ++ formatterPackages;
    languages = {
      language = lib.mapAttrsToList (
        name: value:
        (
          {
            inherit name;
            scope = "source.${name}";
            injection-regex = name;
            file-types = value.fileTypes or [ name ];
            language-servers = [ value.lsp ];
            indent = {
              tab-width = value.indent;
              unit = value.unit or (makeIndentString value.indent);
            };
            auto-format = value.formatter != null;
          }
          // lib.optionalAttrs (value ? comment) {
            comment-tokens = [ value.comment ];
          }
          // lib.optionalAttrs (value.formatter != null) {
            formatter = {
              command = value.formatter;
            };
          }
        )
      ) standards.languages;
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
        rulers = [
          80
          120
        ];
        completion-trigger-len = 1;
        idle-timeout = 0;
        middle-click-paste = true;
        end-of-line-diagnostics = "hint";
        soft-wrap.enable = true;
      };
      editor.cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };
      editor.indent-guides = {
        render = true;
        character = "╎";
      };
      editor.inline-diagnostics = {
        cursor-line = "error";
        other-lines = "disable";
      };
      editor.lsp = {
        display-messages = true;
        display-inlay-hints = true;
        auto-signature-help = false;
      };
      editor.statusline = {
        left = [
          "mode"
          "spinner"
          "file-name"
          "file-modification-indicator"
        ];
        center = [ ];
        right = [
          "diagnostics"
          "selections"
          "position"
          "file-encoding"
          "file-type"
        ];
        mode = {
          normal = "NORMAL";
          insert = "INSERT";
          select = "SELECT";
        };
      };
      editor.whitespace = {
        render = {
          space = "none";
          tab = "all";
          newline = "none";
        };
        characters = {
          tab = "→";
          tabpad = " ";
        };
      };
      editor.file-picker = {
        hidden = false;
        parents = true;
        ignore = true;
        git-ignore = true;
      };
      keys.normal = {
        space = {
          space = "file_picker";
          w = ":w";
          q = ":q";
        };
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";
        "A-/" = "repeat_last_motion";
        "C-," = ":config-open";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };
      keys.insert = {
        j = {
          k = "normal_mode";
        };
      };
    };
  };

  # Create runtime directory to fix health check warnings
  # Helix looks for runtime files in ~/.config/helix/runtime
  # This directory can be empty - Helix will use the Nix store runtime as fallback
  # Using home.file creates the directory structure automatically
  home.file.".config/helix/runtime/.keep" = {
    text = "";
  };
}
