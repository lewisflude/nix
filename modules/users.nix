{
  users.users.lewisflude = {
    name = "lewisflude";
    home = "/Users/lewisflude";
    extraGroups = [ "docker" ];
  };

  # Create docker group
  users.groups.docker = { };
}
