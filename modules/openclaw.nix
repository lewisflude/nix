# OpenClaw: self-hosted AI assistant (CLI + Gateway daemon)
# Upstream flake: github:openclaw/nix-openclaw (provides overlay, HM module,
# systemd user service wiring). Runtime state lives under ~/.openclaw (not XDG).
# Auth via Claude CLI reuse (sanctioned by Anthropic): a one-time
# `claude login` + `openclaw onboard` pairs the gateway to the Max subscription.
{ inputs, ... }:
{
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
      };
    };
}
