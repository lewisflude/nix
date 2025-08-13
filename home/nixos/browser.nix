{ pkgs, ... }:

let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in
{
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };
  programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;

      extensions = {
        force = true;
        packages = with addons; [
          ublock-origin
          kagi-search
          onepassword-password-manager
          firefox-color
        ];
      };

      search = {
        force = true;
        default = "Kagi";
        order = [ "Kagi" ];
        engines.Kagi = {
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          definedAliases = [ "@k" ];
        };
      };
    };
  };

}
