{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pkgs,
  ...
}:
let

  # finalAttrs rather than `rec`: this derivation is immediately .overrideAttrs'd
  # below, and `rec` self-references are fixed at definition time so an override
  # of `version` would not reach `src.rev` or `meta.changelog`.
  # (buildHomeAssistantComponent is built with lib.extendMkDerivation, which
  # threads finalAttrs.) Note that overriding `version` alone still will not
  # work, because `hash` is a literal -- override `version` and `src` together.
  component = buildHomeAssistantComponent (finalAttrs: {
    owner = "acon96";
    domain = "llama_conversation";
    version = "0.3.9";
    src = fetchFromGitHub {
      owner = "acon96";
      repo = "home-llm";
      rev = "v${finalAttrs.version}";
      hash = "sha256-iFsRDm1a5/8nqs36ro+ZZxYT/cIF4dyGoT0nCdyWs9I=";
    };
    meta = {
      changelog = "https://github.com/acon96/home-llm/releases/tag/v${finalAttrs.version}";
      description = "Home LLM is a Home Assistant custom component that allows you to use LLMs to interact with your home automation system.";
      homepage = "https://github.com/acon96/home-llm";
      license = lib.licenses.mit;
      maintainers = [ ];
    };
  });
in

component.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.ninja ];

  propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [
    pkgs.python313Packages.huggingface-hub
    pkgs.python313Packages.webcolors
    pkgs.python313Packages.mcp
  ];
  preBuild = ''


    echo "rule dummy" > build.ninja
    echo "  command = true" >> build.ninja
    ${oldAttrs.preBuild or ""}
  '';
})
