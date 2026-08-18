# Signal Design System - Dendritic Pattern
# Consistent, scientifically-designed colour palette across apps (OKLCH + APCA).
# signal-nix (github:lewisflude/signal-nix) is the user's own theming framework;
# `autoEnable` colours only programs that are already enabled by other modules, so
# this composes with the existing per-app config instead of forcing installs.
{ inputs, ... }:
{
  # ===========================================================================
  # Home Manager: application-layer theming (Linux + Darwin)
  # Themes terminal, editors, shell/prompt, CLI tools, GTK/Qt, etc.
  # ===========================================================================
  flake.modules.homeManager.signal = _: {
    imports = [ inputs.signal-nix.homeManagerModules.default ];
    theming.signal = {
      enable = true;
      mode = "dark";
      autoEnable = true;
      # DankMaterialShell is the sole owner of niri compositor colours (it
      # generates niri's `colors` include). Stop signal's stray KDL export; its
      # only other niri touch is `overview.backdrop-color` via mkDefault, which
      # DMS/niri config override. Harmless no-op on hosts without niri (mercury).
      niri.exportKdl = false;
    };
  };

  # ===========================================================================
  # NixOS: system-level theming (jupiter)
  # The DMS greeter self-themes, so the TTY console palette is the only
  # applicable system target. autoEnable is OFF here on purpose: signal's
  # greeter modules (e.g. regreet) probe now-renamed nixpkgs options and would
  # trigger infinite recursion. With autoEnable = false, Nix's lazy `&&`
  # short-circuits those probes; console theming is gated on
  # `enable && console.enable`, so it is unaffected and still applies.
  # ===========================================================================
  flake.modules.nixos.signal = _: {
    imports = [ inputs.signal-nix.nixosModules.default ];
    theming.signal = {
      enable = true;
      mode = "dark";
      autoEnable = false;
      console.enable = true;
    };
  };
}
