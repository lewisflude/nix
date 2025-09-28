# overlay.nix
final: prev: {

  # nx CLI (from the published npm tarball), built reproducibly via our lockfile.
  nx-latest = prev.buildNpmPackage rec {
    pname = "nx";
    version = "21.5.3";

    # Fetch the upstream published package to preserve its package.json/bin.
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/nx/-/nx-${version}.tgz";
      # Pin the tarball (hash for the tarball itself).
      # Compute once with: nix-prefetch-url --unpack <url>
      hash = "sha256-j/jGtZxoAKVAUVqUZaQCsZcdDthOYzHuk7Im3bGOZBk=";
    };

    # Provide a lockfile we maintain in-repo for nx@21.5.3.
    # This allows fully-offline, reproducible installs.
    postPatch = ''
      cp ${../pkgs/nx/package-lock.json} ./package-lock.json
    '';

    # nx is a CLI package—no build step needed.
    dontNpmBuild = true;

    # Materialize the npm dependency cache deterministically.
    # Compute once with: prefetch-npm-deps ../pkgs/nx/package-lock.json
    npmDepsHash = "sha256-/WdFmNDZZr4npLoWpczr8nFalQGQxAJLQa6Hza1tVBE=";

    meta = with prev.lib; {
      description = "Smart monorepos · Fast CI";
      homepage = "https://nx.dev";
      license = licenses.mit;
      maintainers = [ maintainers.lewisflude ];
      mainProgram = "nx";
    };
  };

  # Google Gemini CLI built from your local source (projen-driven)
  gemini-cli-bin = prev.buildNpmPackage rec {
    pname = "@google/gemini-cli";
    version = "0.6.0";

    # Single source of truth: your local package with package.json + lockfile.
    # Ensure ../pkgs/gemini-cli/package-lock.json exists and is current.
    src = ../pkgs/gemini-cli;

    # Some Google projects have tight peer ranges; this avoids resolution failures.
    npmFlags = [ "--legacy-peer-deps" ];

    # Projen-based workflows often need devDependencies present during build.
    includeDevDependencies = true;

    # Fully offline install using your lockfile’s dependency graph.
    # Compute once with: prefetch-npm-deps ../pkgs/gemini-cli/package-lock.json
    npmDepsHash = "sha256-651LYj4GVEHvqGJ3Gaw0GwFCRLrf639dOSW5IJG6rn0=";

    # If your package.json has a "build" script, the default is fine.
    # If it’s different (e.g. "projen build"), uncomment:
    # npmBuildScript = "projen build";

    meta = with prev.lib; {
      description = "Google Gemini Command Line Interface";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = [ maintainers.lewisflude ];
      # If package.json defines "bin", this exposes it automatically.
    };
  };

}
