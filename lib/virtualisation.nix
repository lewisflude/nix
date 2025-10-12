{lib}: let
  boolKeys = ["enableDocker" "enablePodman"];
  selectKeys = attrs: lib.filterAttrs (name: _: lib.elem name boolKeys) attrs;
  defaults = {
    enableDocker = true;
    enablePodman = true;
  };
in {
  mkModulesVirtualisationArgs = {
    hostVirtualisation ? {},
    overrides ? {},
    extra ? {},
  }:
    defaults
    // selectKeys hostVirtualisation
    // overrides
    // extra;
}
