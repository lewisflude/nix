# Directories where AI coding agents (Claude Code, Codex, Gemini CLI) skip
# permission prompts. Consumers wrap each tool's binary with a zsh function
# that injects the tool's bypass flag when $PWD is under one of these paths.
#
# Paths use $HOME literals so they expand at zsh runtime — keeping the list
# portable across Mercury (/Users/lewisflude) and Jupiter (/home/lewisflude).
{ lib, ... }:
{
  options.trustedDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "$HOME/code"
      "$HOME/Code"
      "$HOME/.config/nix"
    ];
    description = "Directories trusted for unprompted AI agent operations.";
  };
}
