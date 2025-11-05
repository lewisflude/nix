{ pkgs, ... }:
{
  nx-latest = pkgs.buildNpmPackage.override { inherit (pkgs) nodejs; } rec {
    pname = "nx";
    version = "21.5.3";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.com/nx/-/nx-${version}.tgz";
      hash = "sha256-j/jGtZxoAKVAUVqUZaQCsZcdDthOYzHuk7Im3bGOZBk=";
    };
    postPatch = ''
      cp ${../nx/package-lock.json} ./package-lock.json
    '';
    dontNpmBuild = true;
    npmDepsHash = "sha256-/WdFmNDZZr4npLoWpczr8nFalQGQxAJLQa6Hza1tVBE=";
    meta = with pkgs.lib; {
      description = "Smart monorepos · Fast CI";
      homepage = "https://nx.dev";
      license = licenses.mit;
      maintainers = [ maintainers.lewisflude ];
      mainProgram = "nx";
    };
  };
}
