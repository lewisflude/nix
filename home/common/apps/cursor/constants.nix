_:
let
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
    "**.log" = true;
    "**/pid" = true;
    "***.seed" = true;
    "**__pycache__" = true;
    "***$py.class" = true;
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
    "**.pytest_cache/" = true;
    "**/.coverage" = true;
    "**/htmlcov/" = true;
    "**/.tox/" = true;
    "**/.nox/" = true;
    "**/venv/" = true;
    "**/env/" = true;
    "**/ENV/" = true;
    "***.jar" = true;
    "***.ear" = true;
    "**hs_err_pid*" = true;
    "**/bin/" = true;
    "**/obj/" = true;
    "***.suo" = true;
    "**vendor/" = true;
    "***.out" = true;
    "**/target/" = true;
    "***.o" = true;
    "***.so" = true;
    "***.exe" = true;
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
    "***.db" = true;
    "**.dockerignore" = true;
  };
  ideFiles = {
    "**/.idea/" = true;
    "***.ipr" = true;
    "**.vs/" = true;
    "***.sublime-project" = true;
    "***.swp" = true;
    "***~" = true;
    "**/.DS_Store" = true;
    "**/Thumbs.db" = true;
  };
  largeFiles = {
    "***.mp4" = true;
    "***.mkv" = true;
    "***.mp3" = true;
    "***.flac" = true;
    "***.tar" = true;
    "***.rar" = true;
    "***.dmg" = true;
    "**.git/objects.git/subtree-cache.git/index.lock" = true;
    "**/node_modules*.log" = true;
    "**/logs.cachetmptempcoveragedistbuildtarget__pycache__.npm.yarn.pnpm-store.DS_Store" = true;
    "**/.git" = true;
    "**/node_modules" = true;
  };

  # Combined ignore sets
  commonIgnores = systemFiles // vcsFiles // devEnvFiles;
  searchIgnores =
    commonIgnores // nodeFiles // buildFiles // cacheFiles // frameworkFiles // ideFiles;
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
in
{
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
    frameworkFiles
    ideFiles
    largeFiles
    ;
}
