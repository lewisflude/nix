{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    yubioath-flutter
    yubikey-manager
    pam_u2f
  ];

  security.pam = {
    sshAgentAuth.enable = true;
    u2f = {
      enable = true;
      settings = {
        cue = true;
        authFile = "/home/lewis/.config/Yubico/u2f_keys";
      };
    };
    services = {
      login = {
        u2fAuth = true;
      };
      sudo = {
        u2fAuth = true;
        sshAgentAuth = true;
      };
    };
  };
}
