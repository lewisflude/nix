{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pkgs,
  ...
}:
let
  # Home Assistant uses Python 3.13, so we must use Python 3.13 packages
  # buildHomeAssistantComponent uses Python 3.13 by default to match Home Assistant
  # Uses Python 3.13 from nixpkgs-python (via overlay) for better cache coverage

  # Override buildHomeAssistantComponent to skip ninja build step
  # The python-ninja dependency has a setup hook that tries to run ninja,
  # but this package doesn't need it
  # buildHomeAssistantComponent uses Python 3.13 by default to match Home Assistant
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
# Override to add ninja as native build input and create dummy build.ninja
# Also add missing Python dependencies required by manifest.json
# buildHomeAssistantComponent uses Python 3.13, so we must use Python 3.13 packages
# Following NixOS wiki guidelines: https://nixos.wiki/wiki/Home_Assistant
component.overrideAttrs (oldAttrs: {
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.ninja ];
  # Add missing Python dependencies required by manifest.json
  # These are checked during manifestCheckPhase
  # Using Python 3.13 packages to match Home Assistant's Python version
  propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [
    pkgs.python313Packages.huggingface-hub
    pkgs.python313Packages.webcolors
    pkgs.python313Packages.mcp
  ];
  preBuild = ''
    # Create a dummy build.ninja to satisfy the ninja setup hook
    # This package doesn't actually need ninja to build
    echo "rule dummy" > build.ninja
    echo "  command = true" >> build.ninja
    ${oldAttrs.preBuild or ""}
  '';
})
