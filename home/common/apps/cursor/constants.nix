_: {
  # Minimal exclude patterns for Cursor/VS Code
  # Philosophy: Trust Cursor's sensible defaults, only specify:
  # 1. Nix-specific patterns (not in Cursor's defaults)
  # 2. Performance-critical patterns for this repository
  # 3. Patterns that significantly impact file watching/search
  #
  # Cursor already excludes by default:
  # - .DS_Store, Thumbs.db (OS metadata)
  # - .git, .svn, .hg (VCS)
  # - node_modules, bower_components (dependencies)
  # - __pycache__, *.pyc (Python)
  # - And many more: https://code.visualstudio.com/docs/getstarted/settings#_default-settings

  # Core excludes for file search and explorer
  commonIgnores = {
    # Nix: Build outputs (symlinks to /nix/store)
    # Why: Binary outputs, not useful in editor, Nix-specific
    "**/result" = true;
    "**/result-*" = true;

    # Direnv: Shell environment cache
    # Why: Thousands of auto-generated files, high I/O, Nix-specific
    "**/.direnv" = true;

    # Node: Dependencies (explicit for clarity, though Cursor excludes by default)
    # Why: Millions of files in large projects, performance-critical
    "**/node_modules" = true;

    # Rust: Build artifacts
    # Why: Large binary outputs, performance impact
    "**/target" = true;

    # VCS: Git directory (explicit for performance)
    # Why: Large in some repos, already excluded by Cursor but explicit is better
    "**/.git" = true;
  };

  # Watcher-specific excludes (performance-critical)
  # These use /** for recursive exclusion to reduce file system events
  watcherIgnores = {
    # High-churn Nix directories
    "**/.direnv/**" = true;
    "**/result/**" = true;
    "**/result-*/**" = true;

    # Standard high-churn directories
    "**/node_modules/**" = true;
    "**/target/**" = true;
    "**/.git/**" = true;
    "**/.git/objects/**" = true;
    "**/.git/subtree-cache/**" = true;
  };
}
