# Signal Design System — vendored locally under ./vendor/signal-nix.
#
# Previously consumed as the `signal-nix` flake input. It was vendored into this
# repo to drop the external dependency (and to pick up the json2yaml/libffi fix
# for the vivid LS_COLORS derivation on Darwin). This module reproduces the wiring
# that signal-nix's flake did for `homeManagerModules.default`, exposing it as
# `flake.modules.homeManager.signal` for hosts to import.
{ inputs, ... }:
let
  src = ../vendor/signal-nix;

  palette = inputs.signal-palette.palette;
  inherit (inputs) nix-colorizer;

  signalLib = import (src + "/lib") {
    inherit (inputs.nixpkgs) lib;
    inherit palette nix-colorizer;
  };
in
{
  flake.modules.homeManager.signal = import (src + "/modules/common") {
    inherit palette nix-colorizer signalLib;
  };
}
