# Electronic circuit design tooling.
# ngspice is the simulation backend the spicebridge MCP server shells out to
# (see modules/claude-code.nix); cairo backs its schematic rendering/export.
# Declaring them here makes both available on PATH / pkg-config, rather than
# only inside the spicebridge wrapper or as incidental transitive deps.
_:
{
  flake.modules.homeManager.electronics =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ngspice
        pkgs.cairo
      ];
    };
}
