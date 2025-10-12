_: let
  systemFiles = {
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
    "**/Thumbs.db" = true;
    "**/ehthumbs.db" = true;
    "**/Desktop.ini" = true;
    "**/$RECYCLE.BIN/" = true;
    "**/.directory" = true;
    "**/.Trash-*" = true;
  };
  vcsFiles = {
    "**/.git" = true;
    "**/.gitattributes" = true;
    "**/.hg" = true;
    "**/.svn" = true;
    "**/.bzr" = true;
    "**/CVS" = true;
  };
  devEnvFiles = {
    "**/.direnv" = true;
    "**/.envrc" = true;
    "**/.env.local" = true;
    "**/.env.*.local" = true;
    "**/.vscode-test" = true;
  };
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
  languageFiles = {
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
    "**/*.class" = true;
    "**/*.jar" = true;
    "**/*.war" = true;
    "**/*.ear" = true;
    "**/*.nar" = true;
    "**/hs_err_pid*" = true;
    "**/bin/" = true;
    "**/obj/" = true;
    "**/*.user" = true;
    "**/*.suo" = true;
    "**/*.cache" = true;
    "**/vendor/" = true;
    "**/*.test" = true;
    "**/*.out" = true;
    "**/target/" = true;
    "**/*.pdb" = true;
    "**/*.o" = true;
    "**/*.a" = true;
    "**/*.so" = true;
    "**/*.dll" = true;
    "**/*.exe" = true;
  };
  frameworkFiles = {
    "**/.next/" = true;
    "**/out/" = true;
    "**/.nuxt/" = true;
    "**/.angular/" = true;
    "**/.svelte-kit/" = true;
    "**/.cache/" = true;
    "**/public/" = true;
    "**/webpack-stats.json" = true;
    "**/tailwind.config.js.map" = true;
    "**/storybook-static/" = true;
    "**/coverage/" = true;
    "**/.nyc_output/" = true;
    "**/test-results/" = true;
    "**/playwright-report/" = true;
    "**/*.sqlite" = true;
    "**/*.db" = true;
    "**/*.sqlite3" = true;
    "**/.dockerignore" = true;
  };
  ideFiles = {
    "**/.idea/" = true;
    "**/*.iml" = true;
    "**/*.ipr" = true;
    "**/*.iws" = true;
    "**/.vs/" = true;
    "**/*.vscode/" = true;
    "**/*.sublime-project" = true;
    "**/*.sublime-workspace" = true;
    "**/*.swp" = true;
    "**/*.swo" = true;
    "**/*~" = true;
    "**/.DS_Store" = true;
    "**/Thumbs.db" = true;
  };
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
  commonIgnores = systemFiles // vcsFiles // devEnvFiles;
  searchIgnores =
    commonIgnores
    // nodeFiles
    // buildFiles
    // cacheFiles
    // languageFiles
    // frameworkFiles
    // ideFiles;
  watcherIgnores =
    searchIgnores
    // largeFiles
    // {
      "**/.git/objects/**" = true;
      "**/.git/subtree-cache/**" = true;
      "**/.git/index.lock" = true;
      "**/node_modules/**" = true;
      "**/*.log" = true;
      "**/logs/**" = true;
      "**/.cache/**" = true;
      "**/tmp/**" = true;
      "**/temp/**" = true;
      "**/coverage/**" = true;
      "**/dist/**" = true;
      "**/build/**" = true;
      "**/target/**" = true;
      "**/__pycache__/**" = true;
      "**/.npm/**" = true;
      "**/.yarn/**" = true;
      "**/.pnpm-store/**" = true;
    };
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
