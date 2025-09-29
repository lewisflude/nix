# overlay.nix
final: prev: {

  # nx CLI (from the published npm tarball), built reproducibly via our lockfile.
  nx-latest = prev.buildNpmPackage rec {
    pname = "nx";
    version = "21.5.3";

    # Fetch the upstream published package to preserve its package.json/bin.
    src = prev.fetchurl {
      url = "https://registry.npmjs.com/nx/-/nx-${version}.tgz";
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

}
