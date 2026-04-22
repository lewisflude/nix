# Helix editor configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.helix
_:
let
  # Language standards - inline for dendritic pattern
  languageStandards = {
    nix = {
      lsp = "nixd";
      formatter = "nixfmt";
      indent = 2;
    };
    yaml = {
      lsp = "yaml-language-server";
      formatter = "yamlfmt";
      formatterArgs = [ "-" ];
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
  };
in
{
  flake.modules.homeManager.helix =
    {
      lib,
      pkgs,
      ...
    }:
    let
      buildFormatter =
        name: value:
        let
          extraArgs = value.formatterArgs or [ ];
        in
        {
          command = value.formatter;
          args = extraArgs;
        };

      lspPackages = [
        pkgs.nixd
        pkgs.yaml-language-server
        pkgs.taplo
      ];

      formatterPackages = [
        pkgs.nixfmt
        pkgs.yamlfmt
        pkgs.ripgrep
        pkgs.fd
      ];
    in
    {
      programs.helix = {
        enable = true;
        extraPackages = lspPackages ++ formatterPackages;
        languages = {
          language = lib.mapAttrsToList (
            name: value:
            {
              inherit name;
              scope = "source.${name}";
              injection-regex = name;
              file-types = value.fileTypes or [ name ];
              language-servers = [ value.lsp ];
              indent = {
                tab-width = value.indent;
                unit = value.unit or (lib.concatStrings (lib.replicate value.indent " "));
              };
              auto-format = value.formatter != null;
            }
            // lib.optionalAttrs (value ? comment) { comment-tokens = [ value.comment ]; }
            // lib.optionalAttrs (value.formatter != null) { formatter = buildFormatter name value; }
          ) languageStandards;

          language-server = { };
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
            idle-timeout = 50;
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
          keys.insert = {
            j = {
              k = "normal_mode";
            };
          };
        };

        # yj (used by pkgs.formats.toml) truncates TOML keys at the first
        # comma, mangling bindings like "A-,". Emit keys.normal as raw TOML.
        extraConfig = ''
          [keys.normal]
          "A-," = "goto_previous_buffer"
          "A-." = "goto_next_buffer"
          "A-w" = ":buffer-close"
          "A-/" = "repeat_last_motion"
          "C-," = ":config-open"
          esc = ["collapse_selection", "keep_primary_selection"]

          [keys.normal.space]
          space = "file_picker"
          w = ":w"
          q = ":q"
        '';
      };
    };
}
