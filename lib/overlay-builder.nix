{
  inputs,
  system,
}:
final: prev:
let

  overlaySet = import ../overlays {
    inherit inputs;
    inherit system;
  };

  overlayList = builtins.attrValues overlaySet;

  inherit (prev.lib) composeExtensions foldl';
in

(foldl' composeExtensions (_: _: { }) overlayList) final prev
