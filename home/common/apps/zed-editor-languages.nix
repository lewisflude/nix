_:
let
  # Helper: Create a Biome-based language config
  mkBiomeLanguage =
    tabSize: extra:
    let
      extraAttrs = if builtins.isAttrs extra then extra else { };
    in
    {
      tab_size = tabSize;
      code_actions_on_format = {
        "source.fixAll.biome" = true;
      };
      formatter = {
        language_server = {
          name = "biome";
        };
      };
    }
    // extraAttrs;

  # Helper: Create TypeScript-like language with inlay hints
  mkTypeScriptLanguage =
    tabSize:
    mkBiomeLanguage tabSize {
      inlay_hints = {
        enabled = true;
        show_parameter_hints = false;
        show_other_hints = true;
        show_type_hints = true;
      };
    };
in
{
  languages = {
    JavaScript = mkBiomeLanguage 2 { };
    TypeScript = mkTypeScriptLanguage 2;
    TSX = mkBiomeLanguage 2 { };
    CSS = mkBiomeLanguage 2 { };
    HTML = mkBiomeLanguage 2 {
      format_on_save = "on";
    };
    JSON = mkBiomeLanguage 2 { };
    JSONC = mkBiomeLanguage 2 { };
    Markdown = {
      format_on_save = "on";
      remove_trailing_whitespace_on_save = false;
    };
    Nix = {
      tab_size = 2;
      language_servers = [ "nixd" ];
      format_on_save = "on";
    };
    Python = {
      tab_size = 4;
      format_on_save = "on";
      formatter = {
        language_server = {
          name = "ruff";
        };
      };
      language_servers = [
        "pyright"
        "ruff"
      ];
      code_actions_on_format = {
        "source.organizeImports" = true;
        "source.fixAll.ruff" = true;
      };
    };
  };
}
