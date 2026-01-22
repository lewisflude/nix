{
  # Temporarily disabled due to upstream nixpkgs hash mismatch in prompt-toolkit dependency
  # Re-enable once nixpkgs updates the hash
  # Error: hash mismatch in fixed-output derivation affecting python3.13-prompt-toolkit-3.0.51
  programs.awscli = {
    enable = false;
  };
}
