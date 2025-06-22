{ ... }:
let
  publicGitEmail = "lewis@lewisflude.com";
  publicGitUserName = "lewisflude";
in
{
  programs.git = {
    signing.key = "64CA14D5A2396CC0";
    extraConfig.commit.gpgsign = true;
    enable = true;
    userEmail = "${publicGitEmail}";
    userName = "${publicGitUserName}";
  };
}
