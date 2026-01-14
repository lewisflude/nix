# Rustdocs MCP Server Builder
# Uses the rust-docs-mcp flake input for a clean, declarative package
#
# This server provides comprehensive access to Rust crate documentation,
# source code analysis, dependency trees, and module structure visualization.
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
  rust-docs-mcp,
  ...
}:
let
  # Use the default package from the rust-docs-mcp flake input
  # This provides the 'rust-docs-mcp' binary built with proper dependencies
  rust-docs-mcp-pkg = rust-docs-mcp.packages.${rust-docs-mcp.system}.default or rust-docs-mcp.defaultPackage.${rust-docs-mcp.system};
in
{
  rustdocsServer = {
    command = "${rust-docs-mcp-pkg}/bin/rust-docs-mcp";
    args = [ ];
    # No secret required for basic functionality
    # OPENAI_API_KEY only needed if using OpenAI features (optional)
  };
}
