# CLI applications configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.cliApps
# Combines: atuin, bat, direnv, eza, fzf, ripgrep, jq, tealdeer, zellij
{ config, ... }:
{
  flake.modules.homeManager.cliApps = { lib, pkgs, config, ... }: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = { sync_frequency = "5m"; };
    };

    programs.bat.enable = true;

    programs.direnv = {
      enable = true;
      enableZshIntegration = false; # Using cached init script for performance
      nix-direnv.enable = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      colors = "auto";
      git = true;
      icons = "auto";
      extraOptions = [ "--header" "--group-directories-first" ];
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [ "--height 40%" "--border" ];
      defaultCommand = "${lib.getExe pkgs.fd} --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetCommand = "${lib.getExe pkgs.fd} --type f --hidden --strip-cwd-prefix --exclude .git";
    };

    programs.ripgrep = {
      enable = true;
      arguments = [ "--max-columns-preview" "--colors=line:style:bold" ];
    };

    programs.jq.enable = true;

    programs.tealdeer = {
      enable = true;
      settings = {
        display = { compact = true; };
        updates = { auto_update = true; };
      };
    };

    programs.zellij = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        theme = "catppuccin-mocha";
        default_shell = "zsh";
        pane_frames = false;
        default_layout = "compact";
        ui.pane_frames.rounded_corners = true;
      };
    };

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };

    programs.htop.enable = true;
  };
}
