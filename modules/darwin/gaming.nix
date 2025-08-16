{pkgs, ...}: {
  # macOS Game Development Configuration
  environment = {
    systemPackages = with pkgs; [
      # Development tools for Unreal Engine
      cmake
      ninja
      # Audio development libraries
      portaudio
      # Version control and development utilities
      git-lfs # For handling large binary assets in game projects
      # Performance monitoring
      htop
      # Asset conversion tools
      imagemagick
      ffmpeg
      # Documentation tools
      doxygen
    ];

    # Configure Git LFS for game asset management
    etc."gitconfig".text = ''
      [filter "lfs"]
        clean = git-lfs clean -- %f
        smudge = git-lfs smudge -- %f
        process = git-lfs filter-process
        required = true
    '';

    # Increase file descriptor limits for game development
    variables = {
      # Unreal Engine can open many files during compilation
      RLIMIT_NOFILE = "65536";
    };
  };
}
