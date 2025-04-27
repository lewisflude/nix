{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = { switch = "darwin-rebuild switch --flake ~/.config/nix"; };

    initContent = ''
      # GPG and SSH agent configuration
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    '';
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
}
