# NPM packages overlay
#
# PURPOSE:
# Promotes NPM packages to top-level pkgs attributes for easier access.
# This overlay provides the latest version of Nx monorepo tooling.
#
# PERFORMANCE NOTE:
# This overlay does NOT modify build flags, so it doesn't cause cache misses.
# It creates new package derivations using standard Nix build tools.
# Binary caches should contain pre-built versions of these packages.
#
# REMOVAL CONDITIONS:
# This overlay can be removed when:
# 1. The package is added to nixpkgs upstream, OR
# 2. The package is no longer needed in the configuration
#
# TECHNICAL DETAILS:
# - Uses buildNpmPackage to build from npm registry
# - Overrides nodejs to use nodejs_24 (latest LTS)
# - Includes package-lock.json for reproducible builds
#
_final: prev: {
  # Latest Nx monorepo tooling
  # Provides nx-latest as a top-level package for easy access
  nx-latest = prev.buildNpmPackage.override {nodejs = prev.nodejs_24;} rec {
    pname = "nx";
    version = "21.5.3";
    src = prev.fetchurl {
      url = "https://registry.npmjs.com/nx/-/nx-${version}.tgz";
      hash = "sha256-j/jGtZxoAKVAUVqUZaQCsZcdDthOYzHuk7Im3bGOZBk=";
    };
    postPatch = ''
      cp ${../pkgs/nx/package-lock.json} ./package-lock.json
    '';
    dontNpmBuild = true;
    npmDepsHash = "sha256-/WdFmNDZZr4npLoWpczr8nFalQGQxAJLQa6Hza1tVBE=";
    meta = with prev.lib; {
      description = "Smart monorepos · Fast CI";
      homepage = "https://nx.dev";
      license = licenses.mit;
      maintainers = [maintainers.lewisflude];
      mainProgram = "nx";
    };
  };
}
