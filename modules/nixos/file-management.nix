{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nautilus
    code-nautilus
  ];

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };
}
