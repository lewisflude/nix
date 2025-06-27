{
  pkgs,
  ...
}:

let
  u2fMappings = pkgs.writeText "u2f-mappings" ''
    lewis:zCZqXCVWxvg7KqHPYitomeEr4L/Ud7cj6et5M2c9hV/sdboGu13fr8+EqCzJ6p2xO1IhbN/P2LxrKLB4/oEM/A==,ExX8ZCE0glCGICSzsRuMHMbn0o75UI64jrVzZSNpYBbNZhFHrJKAOpJrYS6vd8DbfFiIiK2XmYC4CKLVtv8KXw==,es256,+presence
  '';
in
{

  environment.systemPackages = with pkgs; [
    pam_u2f
    yubikey-manager
    libu2f-host
    libfido2
    yubikey-personalization
    opensc
  ];

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.watchIdAuth = true;

  security.pam.services = {
    sudo_local.text = ''
      auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so cue pinverification=1 userpresence=1
    '';
  };

  environment.etc."u2f-mappings".source = u2fMappings; # immutable store path  [oai_citation:4‡joinemm.dev](https://joinemm.dev/blog/yubikey-nixos-guide)
}
