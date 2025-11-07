_final: prev: {
  ironbar = prev.ironbar.overrideAttrs (oldAttrs: {
    nativeBuildInputs = builtins.map (
      input: if input == prev.wrapGAppsHook or null then prev.wrapGAppsHook3 else input
    ) (oldAttrs.nativeBuildInputs or [ ]);
  });
}
