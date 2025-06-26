{ config, lib, pkgs, ... }:
{
  sops = {
    # Default sops file for system-level secrets
    defaultSopsFile = ./../../secrets/example.yaml;
    
    # Use GPG for decryption (since you have YubiKey setup)
    # GPG home will be the user's home directory
    gnupg.home = "/Users/lewisflude/.gnupg";
    
    # Example secrets configuration
    # secrets.example = {
    #   sopsFile = ../../secrets/example.yaml;
    #   key = "example_secret";
    # };
  };
}