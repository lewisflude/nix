{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Rust and development tools
    rustup
    pkg-config
    openssl
    libiconv
    clang
    cmake
    rustc
    cargo
    rust-analyzer
    rustfmt

    # Crypto tools
    solana-cli
    anchor

    # Database tools
    pgcli
    pgadmin4

    # macOS SDK and development tools
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.CoreFoundation
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.Foundation
    darwin.apple_sdk.frameworks.SystemConfiguration
    darwin.cctools
    darwin.libobjc
    darwin.apple_sdk.libs.xpc

    # Build essentials
    gcc
    gnumake
    cmake
    xcodebuild
  ];

  # Environment variables for building
  environment.variables = {
    LIBRARY_PATH = "/usr/lib:/opt/homebrew/lib:${pkgs.libiconv}/lib";
    CPATH = "${pkgs.libiconv}/include";
    RUSTFLAGS = "-L ${pkgs.libiconv}/lib";
  };

  # Enable OpenSSL
  security.pam.services.sudo_local.touchIdAuth = true;
}
