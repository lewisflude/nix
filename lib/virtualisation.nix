{lib}: let
  inherit (lib) attrByPath isAttrs isBool recursiveUpdate;

  sanitizeVirtualisation = virtualisation:
    if isAttrs virtualisation
    then virtualisation
    else {};

  findBool = virtualisation: path: let
    value = attrByPath path null virtualisation;
  in
    if isBool value
    then value
    else null;

  deriveFlag = virtualisation: globalEnable: pathCandidates: let
    result =
      builtins.foldl'
      (acc: path:
        if acc != null
        then acc
        else findBool virtualisation path)
      null
      pathCandidates;
  in
    if !globalEnable
    then false
    else result;

  optionalFlag = name: value:
    if value == null
    then {}
    else {${name} = value;};
in {
  mkModulesVirtualisationArgs = {hostVirtualisation ? {}}: let
    virtualisation = sanitizeVirtualisation hostVirtualisation;
    globalEnable = findBool virtualisation ["enable"];
    dockerValue = deriveFlag virtualisation globalEnable [
      ["enableDocker"]
      ["docker" "enable"]
      ["docker"]
    ];
    podmanValue = deriveFlag virtualisation globalEnable [
      ["enablePodman"]
      ["podman" "enable"]
      ["podman"]
    ];
    derivedFlags =
      (optionalFlag "enableDocker" dockerValue)
      // (optionalFlag "enablePodman" podmanValue);
  in
    recursiveUpdate virtualisation derivedFlags;
}
