{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  pkgs,
  ...
}:
buildHomeAssistantComponent rec {
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
    python313Packages.bitsandbytes
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
    # changelog, description, homepage, license, maintainers
    changelog = "https://github.com/acon96/home-llm/releases/tag/v${version}";
    description = "Home LLM is a Home Assistant custom component that allows you to use LLMs to interact with your home automation system.";
    homepage = "https://github.com/acon96/home-llm";
    license = licenses.mit;
    maintainers = with maintainers; [];
  };
}
