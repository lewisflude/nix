# Overlay template
# For overriding or adding packages to nixpkgs
# Place in overlays/ directory and import in overlays/default.nix
final: prev: {
  # Override existing package
  example-package = prev.example-package.overrideAttrs (oldAttrs: {
    version = "1.2.3";
    src = final.fetchFromGitHub {
      owner = "owner";
      repo = "repo";
      rev = "v1.2.3";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    
    # Add additional build inputs
    buildInputs = oldAttrs.buildInputs or [] ++ [ final.extra-dep ];
    
    # Modify build flags
    configureFlags = oldAttrs.configureFlags or [] ++ [
      "--enable-feature"
    ];
  });
  
  # Add new custom package
  my-custom-package = final.stdenv.mkDerivation {
    pname = "my-custom-package";
    version = "1.0.0";
    
    src = final.fetchFromGitHub {
      owner = "username";
      repo = "my-custom-package";
      rev = "v1.0.0";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
    
    nativeBuildInputs = with final; [
      pkg-config
      makeWrapper
    ];
    
    buildInputs = with final; [
      # runtime dependencies
    ];
    
    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/bin
      install -Dm755 my-custom-package $out/bin/my-custom-package
      
      runHook postInstall
    '';
    
    meta = with final.lib; {
      description = "Brief description of the package";
      homepage = "https://github.com/username/my-custom-package";
      license = licenses.mit;
      maintainers = [ ];
      platforms = platforms.unix;
    };
  };
  
  # Wrapper around existing package with custom settings
  my-wrapped-package = final.symlinkJoin {
    name = "my-wrapped-package";
    paths = [ final.original-package ];
    buildInputs = [ final.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/original-package \
        --set CUSTOM_VAR "value" \
        --prefix PATH : ${final.lib.makeBinPath [ final.extra-tool ]}
    '';
  };
}
