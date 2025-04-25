{pkgs, lib, ...}: {
  home.stateVersion = "25.05";
  home.packages = with pkgs; [
    vscode
  ];
	programs.zsh = {
	    enable = true;
	    shellAliases = {
		switch = "darwin-rebuild switch --flake ~/.config/nix";
	    };
	};
  programs.home-manager.enable = true;
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.formatOnSave" = true;
    }; 
  };
}
