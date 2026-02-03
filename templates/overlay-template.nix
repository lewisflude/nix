final: prev: {

  example-package = prev.example-package.overrideAttrs (oldAttrs: {
    version = "1.2.3";
    src = final.fetchFromGitHub {
      owner = "owner";
      repo = "repo";
      rev = "v1.2.3";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    buildInputs = oldAttrs.buildInputs or [ ] ++ [ final.extra-dep ];

    configureFlags = oldAttrs.configureFlags or [ ] ++ [
      "--enable-feature"
    ];
  });

  my-custom-package = final.stdenv.mkDerivation {
    pname = "my-custom-package";
    version = "1.0.0";

    src = final.fetchFromGitHub {
      owner = "username";
      repo = "my-custom-package";
      rev = "v1.0.0";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    nativeBuildInputs = [
      final.pkg-config
      final.makeWrapper
    ];

    buildInputs = [

    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      install -Dm755 my-custom-package $out/bin/my-custom-package

      runHook postInstall
    '';

    meta = {
      description = "Brief description of the package";
      homepage = "https://github.com/username/my-custom-package";
      license = final.lib.licenses.mit;
      maintainers = [ ];
      platforms = final.lib.platforms.unix;
    };
  };

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
