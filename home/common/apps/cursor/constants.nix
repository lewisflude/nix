# Shared constants for Cursor/VSCode configuration
# Comprehensive file ignore patterns for modern development environments
# Organized by category for easy maintenance and understanding
_: let
  # ==== SYSTEM & OS FILES ====
  systemFiles = {
    # macOS
    "**/.DS_Store" = true;
    "**/.AppleDouble" = true;
    "**/.LSOverride" = true;
    "**/Icon?" = true;
    "**/.DocumentRevisions-V100" = true;
    "**/.fseventsd" = true;
    "**/.Spotlight-V100" = true;
    "**/.TemporaryItems" = true;
    "**/.Trashes" = true;
    "**/.VolumeIcon.icns" = true;
    "**/.com.apple.timemachine.donotpresent" = true;

    # Windows
    "**/Thumbs.db" = true;
    "**/ehthumbs.db" = true;
    "**/Desktop.ini" = true;
    "**/$RECYCLE.BIN/" = true;

    # Linux
    "**/.directory" = true;
    "**/.Trash-*" = true;
  };

  # ==== VERSION CONTROL ====
  vcsFiles = {
    "**/.git" = true;
    "**/.gitattributes" = true;
    "**/.hg" = true;
    "**/.svn" = true;
    "**/.bzr" = true;
    "**/CVS" = true;
  };

  # ==== DEVELOPMENT ENVIRONMENT ====
  devEnvFiles = {
    "**/.direnv" = true;
    "**/.envrc" = true;
    "**/.env.local" = true;
    "**/.env.*.local" = true;
    "**/.vscode-test" = true;
  };

  # ==== NODE.JS & JAVASCRIPT ECOSYSTEM ====
  nodeFiles = {
    "**/node_modules" = true;
    "**/.npm" = true;
    "**/.yarn" = true;
    "**/.pnpm-store" = true;
    "**/npm-debug.log*" = true;
    "**/yarn-debug.log*" = true;
    "**/yarn-error.log*" = true;
    "**/lerna-debug.log*" = true;
    "**/.eslintcache" = true;
    "**/.stylelintcache" = true;
    "**/.parcel-cache" = true;
    "**/coverage" = true;
    "**/.nyc_output" = true;
  };

  # ==== BUILD OUTPUTS & ARTIFACTS ====
  buildFiles = {
    "**/dist" = true;
    "**/build" = true;
    "**/out" = true;
    "**/target" = true;
    "**/bin" = true;
    "**/obj" = true;
    "**/.next" = true;
    "**/.nuxt" = true;
    "**/.output" = true;
    "**/.vercel" = true;
    "**/.netlify" = true;
    "**/public/build" = true;
    "**/static/build" = true;
  };

  # ==== CACHE & TEMPORARY FILES ====
  cacheFiles = {
    "**/.cache" = true;
    "**/tmp" = true;
    "**/temp" = true;
    "**/.tmp" = true;
    "**/.temp" = true;
    "**/logs" = true;
    "**/*.log" = true;
    "**/.log" = true;
    "**/pid" = true;
    "**/*.pid" = true;
    "**/*.seed" = true;
    "**/*.pid.lock" = true;
  };

  # ==== LANGUAGE-SPECIFIC PATTERNS ====
  languageFiles = {
    # Python
    "**/__pycache__" = true;
    "**/*.py[cod]" = true;
    "**/*$py.class" = true;
    "**/.Python" = true;
    "**/build/" = true;
    "**/develop-eggs/" = true;
    "**/eggs/" = true;
    "**/.eggs/" = true;
    "**/lib/" = true;
    "**/lib64/" = true;
    "**/parts/" = true;
    "**/sdist/" = true;
    "**/var/" = true;
    "**/wheels/" = true;
    "**/*.egg-info/" = true;
    "**/.pytest_cache/" = true;
    "**/.coverage" = true;
    "**/htmlcov/" = true;
    "**/.tox/" = true;
    "**/.nox/" = true;
    "**/venv/" = true;
    "**/env/" = true;
    "**/ENV/" = true;

    # Java
    "**/*.class" = true;
    "**/*.jar" = true;
    "**/*.war" = true;
    "**/*.ear" = true;
    "**/*.nar" = true;
    "**/hs_err_pid*" = true;

    # .NET
    "**/bin/" = true;
    "**/obj/" = true;
    "**/*.user" = true;
    "**/*.suo" = true;
    "**/*.cache" = true;

    # Go
    "**/vendor/" = true;
    "**/*.test" = true;
    "**/*.out" = true;

    # Rust
    "**/target/" = true;
    "**/*.pdb" = true;

    # C/C++
    "**/*.o" = true;
    "**/*.a" = true;
    "**/*.so" = true;
    "**/*.dll" = true;
    "**/*.exe" = true;
  };

  # ==== FRAMEWORK & TOOL SPECIFIC ====
  frameworkFiles = {
    # React/Next.js
    "**/.next/" = true;
    "**/out/" = true;

    # Vue/Nuxt
    "**/.nuxt/" = true;

    # Angular
    "**/.angular/" = true;

    # Svelte/SvelteKit
    "**/.svelte-kit/" = true;

    # Gatsby
    "**/.cache/" = true;
    "**/public/" = true;

    # Webpack
    "**/webpack-stats.json" = true;

    # Tailwind
    "**/tailwind.config.js.map" = true;

    # Storybook
    "**/storybook-static/" = true;

    # Testing
    "**/coverage/" = true;
    "**/.nyc_output/" = true;
    "**/test-results/" = true;
    "**/playwright-report/" = true;

    # Databases
    "**/*.sqlite" = true;
    "**/*.db" = true;
    "**/*.sqlite3" = true;

    # Docker
    "**/.dockerignore" = true;
  };

  # ==== IDE & EDITOR FILES ====
  ideFiles = {
    # JetBrains
    "**/.idea/" = true;
    "**/*.iml" = true;
    "**/*.ipr" = true;
    "**/*.iws" = true;

    # Visual Studio
    "**/.vs/" = true;
    "**/*.vscode/" = true;

    # Sublime Text
    "**/*.sublime-project" = true;
    "**/*.sublime-workspace" = true;

    # Vim
    "**/*.swp" = true;
    "**/*.swo" = true;

    # Emacs
    "**/*~" = true;
    "**/#*#" = true;
    "**/.#*" = true;
  };

  # ==== LARGE FILES & MEDIA ====
  largeFiles = {
    "**/*.mov" = true;
    "**/*.mp4" = true;
    "**/*.avi" = true;
    "**/*.mkv" = true;
    "**/*.wmv" = true;
    "**/*.mp3" = true;
    "**/*.wav" = true;
    "**/*.flac" = true;
    "**/*.zip" = true;
    "**/*.tar" = true;
    "**/*.tar.gz" = true;
    "**/*.rar" = true;
    "**/*.7z" = true;
    "**/*.dmg" = true;
    "**/*.iso" = true;
  };

  # ==== BASE IGNORE PATTERNS ====
  # Essential files that should always be ignored
  commonIgnores = systemFiles // vcsFiles // devEnvFiles;

  # ==== COMPREHENSIVE IGNORE PATTERNS ====
  # Extended ignore patterns for search operations
  searchIgnores =
    commonIgnores
    // nodeFiles
    // buildFiles
    // cacheFiles
    // languageFiles
    // frameworkFiles
    // ideFiles;

  # ==== FILE WATCHER EXCLUSIONS ====
  # Files to exclude from file watching (performance critical)
  watcherIgnores =
    searchIgnores
    // largeFiles
    // {
      # Additional watcher-specific exclusions for performance
      "**/.git/objects/**" = true;
      "**/.git/subtree-cache/**" = true;
      "**/.git/index.lock" = true;
      "**/node_modules/**" = true;
      "**/*.log" = true;
      "**/logs/**" = true;
      "**/.cache/**" = true;
      "**/tmp/**" = true;
      "**/temp/**" = true;

      # Large directories that change frequently
      "**/coverage/**" = true;
      "**/dist/**" = true;
      "**/build/**" = true;
      "**/target/**" = true;
      "**/__pycache__/**" = true;

      # Package manager caches
      "**/.npm/**" = true;
      "**/.yarn/**" = true;
      "**/.pnpm-store/**" = true;
    };

  # ==== MINIMAL IGNORE PATTERNS ====
  # For contexts where we want minimal exclusions
  minimalIgnores = {
    "**/.DS_Store" = true;
    "**/.git" = true;
    "**/node_modules" = true;
  };
in {
  inherit
    commonIgnores
    searchIgnores
    watcherIgnores
    minimalIgnores
    systemFiles
    vcsFiles
    devEnvFiles
    nodeFiles
    buildFiles
    cacheFiles
    languageFiles
    frameworkFiles
    ideFiles
    largeFiles
    ;
}
