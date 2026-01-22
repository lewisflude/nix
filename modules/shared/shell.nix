{ lib, ... }:
{
  programs.zsh = {
    enable = lib.mkDefault true;

    # Disable global compinit - Home Manager handles it with caching
    enableGlobalCompInit = lib.mkDefault false;

    # Enable bash completion compatibility
    enableBashCompletion = lib.mkDefault true;

    # Disable system prompt - users manage their own (e.g. Powerlevel10k)
    # Load promptinit (provides 'prompt' command) and disable system prompt
    promptInit = lib.mkDefault "autoload -U promptinit && promptinit && prompt off";
  };
}
