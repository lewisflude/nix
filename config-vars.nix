{
  # User configuration
  email = "lewis@lewisflude.com";
  fullName = "Lewis Flude";

  # System preferences
  timezone = "America/New_York";
  locale = "en_US.UTF-8";

  # Development preferences
  editor = "helix";
  shell = "zsh";

  # Theme preferences
  theme = {
    name = "catppuccin";
    variant = "mocha";
    accent = "mauve";
  };

  # Security settings
  ssh = {
    keyType = "ed25519";
    keyBits = 4096;
  };

  # Development environment
  languages = {
    node = "24";
    python = "3.13";
    rust = "stable";
  };

  # macOS specific
  darwin = {
    dock = {
      autohide = true;
      position = "bottom";
      tilesize = 48;
    };
    finder = {
      showPathbar = true;
      showStatusbar = true;
      showExtensions = true;
    };
  };

  # Linux specific
  linux = {
    compositor = "niri";
    displayManager = "sddm";
    audioSystem = "pipewire";
  };
}
