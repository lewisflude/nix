{ self, ... }: {
  nix.settings.experimental-features = "nix-command flakes";
  nix.enable = false;
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
}
