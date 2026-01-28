{ pkgs, config, ... }:
let
  u2fMappings = pkgs.writeText "u2f-mappings" ''
    ${config.host.username}:zCZqXCVWxvg7KqHPYitomeEr4L/Ud7cj6et5M2c9hV/sdboGu13fr8+EqCzJ6p2xO1IhbN/P2LxrKLB4/oEM/A==,ExX8ZCE0glCGICSzsRuMHMbn0o75UI64jrVzZSNpYBbNZhFHrJKAOpJrYS6vd8DbfFiIiK2XmYC4CKLVtv8KXw==,es256,+presence
  '';
in
{
  security.pam.services = {
    sudo_local = {
      touchIdAuth = true;
      watchIdAuth = false;
      text = ''
        auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so authfile=/etc/u2f-mappings cue origin=pam://yubi pinverification=1 userpresence=1
      '';
    };
  };
  environment.etc."u2f-mappings" = {
    source = u2fMappings;
  };
}
