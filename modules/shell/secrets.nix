# Lazy secret loading for CLI tools.
#
# Each secret is read on first use of the command that needs it. Nothing is
# exported from .zshenv: that file runs for every zsh process, including
# non-interactive scripts, so anything exported there is read from disk on every
# shell spawn and inherited by every child process. The previous config exported
# GITHUB_TOKEN eagerly there, which also made its lazy wrapper dead code.
_: {
  flake.modules.homeManager.shell =
    {
      lib,
      osConfig ? { },
      ...
    }:
    let
      # command -> environment variable holding its credential
      lazySecrets = {
        gh = "GITHUB_TOKEN";
        kagi = "KAGI_API_KEY";
      };

      available = name: osConfig ? sops && osConfig.sops ? secrets && osConfig.sops.secrets ? ${name};

      wrapper =
        cmd: var:
        let
          path = lib.escapeShellArg osConfig.sops.secrets.${var}.path;
        in
        ''
          function ${cmd}() {
            if [[ -z "''$${var}" && -r ${path} ]]; then
              export ${var}="$(<${path})"
            fi
            command ${cmd} "$@"
          }
        '';
    in
    {
      programs.zsh.initContent = lib.mkAfter (
        lib.concatStrings (
          lib.mapAttrsToList (cmd: var: lib.optionalString (available var) (wrapper cmd var)) lazySecrets
        )
      );
    };
}
