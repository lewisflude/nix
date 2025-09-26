final: prev: {
  # Custom npm packages not available in nixpkgs nodePackages
  #
  # Template for adding new packages:
  # my-npm-package = prev.buildNpmPackage rec {
  #   pname = "package-name";
  #   version = "x.y.z";
  #
  #   src = prev.fetchFromNpm {
  #     inherit pname version;
  #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   };
  #   # OR for GitHub sources:
  #   # src = prev.fetchFromGitHub {
  #   #   owner = "username";
  #   #   repo = "repo-name";
  #   #   rev = "v${version}";
  #   #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   # };
  #
  #   npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #
  #   meta = with prev.lib; {
  #     description = "Package description";
  #     homepage = "https://...";
  #     license = licenses.mit; # or appropriate license
  #     maintainers = [ maintainers.your-username ];
  #   };
  # };

  nx-latest = prev.buildNpmPackage rec {
    pname = "nx";
    version = "21.5.3";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/nx/-/nx-${version}.tgz";
      hash = "sha256-j/jGtZxoAKVAUVqUZaQCsZcdDthOYzHuk7Im3bGOZBk=";
    };

    # Add the package-lock.json to the source
    packageLock = ../pkgs/nx/package-lock.json;

    # Copy the package-lock.json into the build directory
    postPatch = ''
      cp ${packageLock} package-lock.json
    '';

    dontNpmBuild = true;

    npmDepsHash = "sha256-/WdFmNDZZr4npLoWpczr8nFalQGQxAJLQa6Hza1tVBE=";

    meta = with prev.lib; {
      description = "Smart monorepos · Fast CI";
      homepage = "https://nx.dev";
      license = licenses.mit;
    };
  };

  gemini-cli-bin = prev.buildNpmPackage rec {
    pname = "@google/gemini-cli";
    version = "0.6.0";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Placeholder: Replace with actual hash
    };

    npmDepsHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Placeholder: Replace with actual hash

    meta = with prev.lib; {
      description = "Google Gemini Command Line Interface";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.apache20; # Assuming Apache 2.0 based on Google projects
      maintainers = [ "your-username" ]; # Replace with your GitHub username
    };
  };


}
