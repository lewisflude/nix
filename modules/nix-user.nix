# Nix user configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.nixUser
#
# The GitHub access token lives in a sops template rendered by the system
# (see modules/sops.nix); nix.conf only `!include`s it, so no secret is ever
# written to the store and a missing template is silently skipped.
_: {
  flake.modules.homeManager.nixUser =
    {
      config,
      lib,
      osConfig ? { },
      ...
    }:
    let
      tokensPath = osConfig.sops.templates."nix-access-tokens.conf".path or null;
    in
    {
      home.sessionVariables = {
        NIX_USER_CONF_FILES = "${config.xdg.configHome}/nix/nix.conf";
      };

      xdg.configFile."nix/nix.conf" = lib.mkIf (tokensPath != null) {
        # Replaces the regular file the old activation script wrote.
        force = true;
        text = ''
          !include ${tokensPath}
        '';
      };
    };
}
