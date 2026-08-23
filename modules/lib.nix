# Shared library functions
# Dendritic pattern: Exposes myLib as a top-level option (like config.constants)
{ lib, ... }:
let
  # Hoisted out of the attrset so the helpers can compose without `rec`, which
  # nix.dev lists as an anti-pattern (shadowing a name inside `rec` produces
  # hard-to-debug infinite recursion). Consumers still see one `config.myLib`.
  isDarwin = system: lib.hasSuffix "-darwin" system;

  homeDir = system: username: if isDarwin system then "/Users/${username}" else "/home/${username}";

  myLib = {
    # Cross-platform path helpers (composed from homeDir)
    inherit homeDir;
    configDir = system: username: "${homeDir system username}/.config";
    dataDir =
      system: username:
      if isDarwin system then
        "${homeDir system username}/Library/Application Support"
      else
        "${homeDir system username}/.local/share";

    # Pkgs configuration for nixpkgs import
    mkPkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBrokenPredicate =
        pkg:
        let
          name = toString (pkg.name or "");
        in
        lib.hasPrefix "zfs-kernel" name || name == "postgresql-test-hook";
      allowUnsupportedSystem = false;
    };
  };
in
{
  options.myLib = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    # Repo plumbing, not a user-facing knob. `internal` excludes it from any
    # generated option docs, which settles the `defaultText` question for a
    # lambda-bearing default -- see NIX_PRACTICES.md section 3.5.
    internal = true;
    visible = false;
    default = myLib;
    description = "Shared library functions (path helpers, pkgs config)";
  };
}
