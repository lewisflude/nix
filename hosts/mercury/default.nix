{
  username = "lewisflude";
  useremail = "lewis@lewisflude.com";
  system = "aarch64-darwin";
  hostname = "mercury";

  features = {
    security = {
      enable = true;
      yubikey = true;
    };

    productivity = {
      enable = true;
      notes = true;
      resume = true;
    };
  };
}
