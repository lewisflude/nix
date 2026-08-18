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
      # generates niri's `colors` include), so exclude niri from signal theming
      # entirely. Harmless on hosts without niri (mercury).
      exclude = [ "niri" ];
    };
  };

  # ===========================================================================
  # NixOS: system-level theming (jupiter)
  # autoEnable themes whatever supported system targets are enabled; the TTY
  # console is opt-in (gated on enable && console.enable, not autoEnable). The
  # DMS greeter self-themes and jupiter doesn't use regreet, so nothing else
  # here activates. (The old autoEnable=false workaround for signal's regreet
  # recursion is no longer needed — fixed upstream as of the pinned rev.)
  # ===========================================================================
  flake.modules.nixos.signal = _: {
    imports = [ inputs.signal-nix.nixosModules.default ];
    theming.signal = {
      enable = true;
      mode = "dark";
      autoEnable = true;
      console.enable = true;
    };
  };
}
