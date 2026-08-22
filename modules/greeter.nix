# Greeter Configuration
# greetd auto-login straight into a niri session.
#
# The DankMaterialShell greeter used to live in the dms flake as
# `programs.dank-material-shell.greeter`. Upstream moved it to a separate
# dank-greeter repo (`programs.dms-greeter`) and left `nixosModules.greeter`
# as an empty stub, so the old option no longer exists. We don't re-add it:
# auto-login skips the login screen entirely, so a greeter UI would never be
# shown. greetd itself is still what starts the session.
{ inputs, config, ... }:
let
  # Captured from the top-level scope before the NixOS module shadows `config`.
  inherit (config) username;
in
{
  flake.modules.nixos.greeterAutoLogin =
    { pkgs, config, ... }:
    let
      niri = inputs.niri.packages.${config.nixpkgs.hostPlatform.system}.niri-unstable;
      session = {
        command = "${pkgs.uwsm}/bin/uwsm start -- ${niri}/bin/niri-session";
        user = username;
      };
    in
    {
      services.greetd = {
        enable = true;
        settings = {
          initial_session = session;
          default_session = session;
        };
      };
    };
}
