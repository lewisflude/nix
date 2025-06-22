{ pkgs, cursor, ... }: {
  home.sessionVariables = {
    EDITOR = "hx";
    SUDO_EDITOR = "hx";
  };
  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    helix
    nodePackages.eslint
    nodePackages.prettier
    claude-code
  ];
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        line-number = "relative";
        lsp.display-messages = true;
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          scope = "source.nix";
          injection-regex = "nix";
          file-types = [ "nix" ];
          comment-token = "#";
          language-servers = [ "nil" ];
          indent = {
            tab-width = 2;
            unit = "  ";
          };
          formatter = {
            command = "nixpkgs-fmt";
          };
          auto-format = true;
        }
      ];
    };
  };
}
