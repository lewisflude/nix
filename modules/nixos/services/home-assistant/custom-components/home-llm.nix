{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pkgs,
  ...
}:
let
  # Override buildHomeAssistantComponent to skip ninja build step
  # The python-ninja dependency has a setup hook that tries to run ninja,
  # but this package doesn't need it
  component = buildHomeAssistantComponent rec {
    owner = "acon96";
    domain = "llama_conversation";
    version = "0.3.9";
    src = fetchFromGitHub {
      owner = "acon96";
      repo = "home-llm";
      rev = "v${version}";
      hash = "sha256-iFsRDm1a5/8nqs36ro+ZZxYT/cIF4dyGoT0nCdyWs9I=";
    };
    dependencies = with pkgs; [
      python313Packages.transformers
      python313Packages.tensorboard
      python313Packages.datasets
      python313Packages.peft
      python313Packages.trl
      python313Packages.webcolors
      python313Packages.pandas
      python313Packages.sentencepiece
      python313Packages.deep-translator
      python313Packages.langcodes
      python313Packages.babel
      python313Packages.huggingface-hub
    ];
    meta = with lib; {
      changelog = "https://github.com/acon96/home-llm/releases/tag/v${version}";
      description = "Home LLM is a Home Assistant custom component that allows you to use LLMs to interact with your home automation system.";
      homepage = "https://github.com/acon96/home-llm";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };
in
# Override to add ninja as native build input and create dummy build.ninja
component.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.ninja ];
  preBuild = ''
    # Create a dummy build.ninja to satisfy the ninja setup hook
    # This package doesn't actually need ninja to build
    echo "rule dummy" > build.ninja
    echo "  command = true" >> build.ninja
    ${oldAttrs.preBuild or ""}
  '';
})
