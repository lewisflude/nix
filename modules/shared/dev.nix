{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # System-level development dependencies
    pkg-config
    openssl
    libiconv
  
    cmake

    # macOS SDK and development tools
    # Note: Updated Darwin SDK references for future compatibility

    # Build essentials
    gnumake
    xcodebuild
  ];

  # Environment variables for building
  environment.variables = {
    LIBRARY_PATH = "/usr/lib:/opt/homebrew/lib:${pkgs.libiconv}/lib";
    CPATH = "${pkgs.libiconv}/include";
    RUSTFLAGS = "-L ${pkgs.libiconv}/lib";
  };
}
