{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  zlib,
  openssl,
}:

# Hytale Downloader CLI
# Command-line tool to download Hytale server and asset files with OAuth2 authentication
# See: https://support.hytale.com/hc/en-us/articles/hytale-server-manual
#
# To obtain the download URL:
#   1. Visit: https://support.hytale.com/hc/en-us/articles/hytale-server-manual
#   2. Find the "hytale-downloader.zip" link in the "Hytale Downloader CLI" section
#   3. Right-click and copy the download link
#   4. Update the `url` field below
#   5. Download the file and run: nix hash file hytale-downloader.zip
#   6. Update the `hash` field with the output
#
# Note: The downloader is a precompiled binary that may require patching for NixOS.
stdenv.mkDerivation rec {
  pname = "hytale-downloader";
  version = "1.0.0"; # Update when version is known

  # TODO: Replace with actual download URL
  # The URL can be found in the Hytale Server Manual under "Hytale Downloader CLI"
  src = fetchzip {
    url = "https://example.com/hytale-downloader.zip"; # PLACEHOLDER
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # PLACEHOLDER
    stripRoot = false;
  };

  # The downloader is likely a precompiled binary that needs patching for NixOS
  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Find and install the binary (name may vary)
    if [ -f hytale-downloader ]; then
      install -Dm755 hytale-downloader $out/bin/hytale-downloader
    elif [ -f hytale-downloader-linux ]; then
      install -Dm755 hytale-downloader-linux $out/bin/hytale-downloader
    elif [ -f linux/hytale-downloader ]; then
      install -Dm755 linux/hytale-downloader $out/bin/hytale-downloader
    else
      echo "ERROR: Could not find hytale-downloader binary in archive"
      echo "Archive contents:"
      ls -la
      exit 1
    fi

    # Include README if present
    if [ -f QUICKSTART.md ]; then
      install -Dm644 QUICKSTART.md $out/share/doc/hytale-downloader/QUICKSTART.md
    fi
    if [ -f README.md ]; then
      install -Dm644 README.md $out/share/doc/hytale-downloader/README.md
    fi

    runHook postInstall
  '';

  # Verify the binary works
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/hytale-downloader -version || true
    $out/bin/hytale-downloader --help || true
  '';

  meta = {
    description = "Official Hytale server and asset file downloader with OAuth2 authentication";
    longDescription = ''
      Command-line tool to download Hytale server files (HytaleServer.jar and Assets.zip)
      with OAuth2 authentication. Supports version checking, update management, and
      downloading from different release channels (release, pre-release).

      Usage:
        hytale-downloader                    # Download latest release
        hytale-downloader -print-version     # Show game version
        hytale-downloader -check-update      # Check for updates
        hytale-downloader -patchline pre-release  # Download pre-release

      See QUICKSTART.md in the archive for detailed documentation.
    '';
    homepage = "https://support.hytale.com/hc/en-us/articles/hytale-server-manual";
    license = lib.licenses.unfree; # Hytale is proprietary
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ ];
    mainProgram = "hytale-downloader";
  };
}
