{ config, lib, pkgs, ... }: {
  home.packages = [ pkgs.gnupg pkgs.pinentry_mac ];

  home.file.".gnupg/gpg-agent.conf" = {
    text = ''
      enable-ssh-support
      default-cache-ttl 60
      max-cache-ttl 120
      pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    '';
    onChange = ''
      gpgconf --kill gpg-agent
      gpgconf --launch gpg-agent
    '';
  };

  home.file.".gnupg/common.conf" = { text = "use-keyboxd"; };

  home.activation.gpgSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ~/.gnupg
    $DRY_RUN_CMD chmod 700 ~/.gnupg
  '';

  home.sessionVariables = { GPG_TTY = "$(tty)"; };
}
