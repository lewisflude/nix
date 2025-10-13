# Darwin host configuration for Lewis's MacBook Pro
{
  # System identification
  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "aarch64-darwin";
  hostname = "Lewiss-MacBook-Pro";
  
  # Feature configuration
  features = {
    development = {
      enable = true;
      rust = true;
      python = true;
      go = true;
      node = true;
      docker = false;  # Docker Desktop managed separately on macOS
    };
    
    gaming.enable = false;  # Not applicable on macOS
    
    virtualisation = {
      enable = false;
      docker = false;
      podman = false;
    };
    
    desktop = {
      enable = true;
      theming = true;
    };
    
    security = {
      enable = true;
      yubikey = true;
      gpg = true;
    };
    
    productivity = {
      enable = true;
      notes = true;
    };
  };
}
