# OpenClaw: self-hosted AI assistant (CLI + Gateway daemon)
# Upstream flake: github:openclaw/nix-openclaw (provides overlay, HM module,
# systemd user service wiring). Runtime state lives under ~/.openclaw (not XDG).
# Auth via Claude CLI reuse (sanctioned by Anthropic): a one-time
# `claude login` + `openclaw onboard` pairs the gateway to the Max subscription.
{ inputs, ... }:
{
  # Replaces pkgs.openclaw with the version the home-manager module expects;
  # also adds openclaw-gateway etc.
  overlays.nix-openclaw = inputs.nix-openclaw.overlays.default;

  flake.modules.homeManager.openclaw =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

      config = lib.mkIf pkgs.stdenv.isLinux {
        programs.openclaw = {
          enable = true;
          installApp = false;

          config.agents.defaults = {
            model.primary = "anthropic/claude-sonnet-4-6";
            cliBackends."claude-cli" = {
              command = "${pkgs.claude-code}/bin/claude";
              jsonlDialect = "claude-stream-json";
            };
          };
        };

        # Upstream HM module declares home.file."<configPath>" *and* runs
        # `ln -sfn` against the same path during activation. The activation
        # script is the intended authority; the home.file entry just trips
        # checkLinkTargets when the rendered store path changes, exhausting
        # the .hm-backup slot. Defer to the activation script.
        home.file.".openclaw/openclaw.json".force = true;
      };
    };
}
