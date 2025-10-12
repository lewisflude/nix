{
  username = "lewis";
  useremail = "lewis@lewisflude.com";
  system = "x86_64-linux";
  hostname = "jupiter";
  virtualisation = {
    enableDocker = true;
    enablePodman = true;
    stacks = {
      default = {
        path = "/opt/stacks/default";
      };
    };
  };
}
