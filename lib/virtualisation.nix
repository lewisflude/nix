{ lib }:
let
  inherit (lib) isAttrs recursiveUpdate;

  sanitizeVirtualisation = virtualisation: if isAttrs virtualisation then virtualisation else { };
in
{
  # Normalize virtualisation config to standard format
  # Accepts: features.virtualisation.{enable, docker, podman}
  # Outputs: { enable, enableDocker, enablePodman }
  mkModulesVirtualisationArgs =
    {
      hostVirtualisation ? { },
    }:
    let
      virtualisation = sanitizeVirtualisation hostVirtualisation;
      globalEnable = virtualisation.enable or false;

      # Normalize docker flag - accept docker as boolean or enableDocker
      enableDocker =
        if !globalEnable then false else (virtualisation.enableDocker or virtualisation.docker or false);

      # Normalize podman flag - accept podman as boolean or enablePodman
      enablePodman =
        if !globalEnable then false else (virtualisation.enablePodman or virtualisation.podman or false);
    in
    recursiveUpdate virtualisation {
      enable = globalEnable;
      inherit enableDocker enablePodman;
    };
}
