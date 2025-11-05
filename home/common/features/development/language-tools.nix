# Language-specific tools and formatters
# This module provides additional tools not included in the main development feature
# All toolchain packages are handled by the main feature module via package-sets.nix
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # General formatters/linters that work across languages
    # Note: These are also in packageSets.languageFormatters.general,
    # but included here for backward compatibility
    biome
    taplo
    marksman

    # Lua-specific tool (not in main toolchain)
    luaPackages.luacheck

    # Lua interpreter fallback (for compatibility)
    # Note: luajit is in packageSets.luaToolchain
    (lib.lowPrio lua) # Fallback Lua 5.2 (lower priority to avoid conflict)
  ]
  # All major toolchain packages are now handled by the main feature module
  # This file only contains additional/supplemental tools
  # Removed duplicates:
  # - python312, pip, virtualenv, uv, ruff, pyright -> in packageSets.pythonToolchain
  # - go, gopls, gotools, delve -> in packageSets.goToolchain
  # - nodejs_24 -> in packageSets.nodeToolchain
  # - luajit, luarocks, lua-language-server -> in packageSets.luaToolchain
  # - nixfmt-rfc-style, nixd -> in packageSets.nixTools
  # - lldb -> in packageSets.debugTools (included in mkHomePackages)
  # - stylua, selene -> in packageSets.luaToolchain
  ;
}
