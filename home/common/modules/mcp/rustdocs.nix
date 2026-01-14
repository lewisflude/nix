# Rustdocs MCP Server Builder
# TEMPORARILY DISABLED: Upstream uses deprecated apple_sdk_11_0
#
# This server provides comprehensive access to Rust crate documentation,
# source code analysis, dependency trees, and module structure visualization.
#
# TODO: Re-enable once upstream fixes apple_sdk_11_0 deprecation
# See: https://github.com/snowmead/rust-docs-mcp
#
# Usage:
#   - Enable in your platform-specific MCP config (home/{nixos,darwin}/mcp.nix)
#   - Use MCP tools like `cache_crate` to load crates dynamically
#   - No pre-loading needed - crates are cached on-demand
#
# Available tools:
#   - cache_crate: Download and cache crates (crates.io, GitHub, local)
#   - search_items: Search documentation with fuzzy matching
#   - get_item_details: View detailed type/function signatures
#   - get_dependencies: Analyze dependency trees
#   - structure: Generate module hierarchy visualizations
{
  pkgs,
  ...
}:
{
  rustdocsServer = {
    # Placeholder command - server is disabled due to upstream build issue
    command = "${pkgs.coreutils}/bin/echo";
    args = [ "rust-docs-mcp is temporarily disabled due to upstream apple_sdk_11_0 deprecation" ];
    enabled = false;
  };
}
