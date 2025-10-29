{pkgs, ...}: {
  programs.obsidian = {
    enable = true;
    package = pkgs.obsidian;
    vaults = {
      "Obsidian Vault" = {
        enable = true;
      };
    };
  };
}
