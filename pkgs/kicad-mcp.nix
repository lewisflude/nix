# KiCAD MCP Server (mixelpixx/KiCAD-MCP-Server) — a Node/TypeScript MCP server
# that drives KiCAD via its Python `pcbnew` bindings. It is not published to npm
# and not in nixpkgs, so we build it from the pinned flake input.
#
# The Python side is deliberately NOT built here. At runtime the server spawns
# KiCAD's own bundled Python (selected via the KICAD_PYTHON env var set by the
# MCP wrapper in modules/claude-code.nix) so that `pcbnew`'s ABI matches the
# installed KiCAD. This derivation only compiles the TypeScript server (`tsc`)
# and bundles its Node dependencies. The whole built tree is preserved because
# the server reads sibling `python/` and `resources/` dirs relative to `dist/`.
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
  src,
}:

buildNpmPackage (finalAttrs: {
  pname = "kicad-mcp";

  # Read out of the pinned source itself so it cannot disagree with what is
  # actually being built. Not IFD: `src` is a flake input, i.e. already a
  # realised store path at eval time.
  inherit ((lib.importJSON "${src}/package.json")) version;

  inherit src;

  # Computed with `prefetch-npm-deps package-lock.json`. Bump when the input's
  # package-lock.json changes.
  npmDepsHash = "sha256-LBUZmYzYnaVyuU0/fwy6t3yoIIb8Qbve/mF/Fv6Y6qg=";

  nativeBuildInputs = [ makeWrapper ];

  # `npm run build` (tsc) is the default build script, no extra setup needed.
  # Skip buildNpmPackage's global npm-install step and lay the project out by
  # hand so runtime-relative paths (python/, resources/) keep working.
  dontNpmInstall = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/kicad-mcp $out/bin
    cp -r . $out/lib/kicad-mcp/

    makeWrapper ${lib.getExe nodejs} $out/bin/kicad-mcp \
      --add-flags $out/lib/kicad-mcp/dist/index.js

    runHook postInstall
  '';

  meta = {
    description = "MCP server for KiCAD PCB design automation";
    homepage = "https://github.com/mixelpixx/KiCAD-MCP-Server";
    license = lib.licenses.mit;
    mainProgram = "kicad-mcp";
    platforms = lib.platforms.all;
  };
})
