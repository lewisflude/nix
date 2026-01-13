# Property registry - imports all property categories
{
  colors,
  withAlpha,
  cat,
  ...
}:
let
  borders = import ./borders.nix { inherit colors withAlpha; };
  surfaces = import ./surfaces.nix { inherit colors withAlpha; };
  text = import ./text.nix { inherit colors; };
  icons = import ./icons.nix { inherit colors; };
  ui = import ./ui.nix { inherit colors withAlpha; };
  scrollbar = import ./scrollbar.nix { inherit colors withAlpha; };
  editor = import ./editor.nix { inherit colors withAlpha; };
  terminal = import ./terminal.nix { inherit colors withAlpha; };
  diagnostics = import ./diagnostics.nix { inherit colors withAlpha; };
  players = import ./players.nix { inherit colors withAlpha cat; };
  syntax = import ./syntax.nix { inherit colors cat; };
in
{
  # Merge all property categories
  style =
    borders
    // surfaces
    // text
    // icons
    // ui
    // scrollbar
    // editor
    // terminal
    // {
      "link_text.hover" = colors."accent-focus".hex + "ff";
    }
    // diagnostics
    // {
      accents = [ ];
      inherit players;
      inherit syntax;
    };
}
