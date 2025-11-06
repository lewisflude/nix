{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pkgs,
  ...
}:
let

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
    meta = with lib; {
      changelog = "https://github.com/acon96/home-llm/releases/tag/v${version}";
      description = "Home LLM is a Home Assistant custom component that allows you to use LLMs to interact with your home automation system.";
      homepage = "https://github.com/acon96/home-llm";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
    };
  };
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
