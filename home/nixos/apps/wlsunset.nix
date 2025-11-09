{ }:
{
  services.wlsunset = {
    enable = true;
    # London, UK coordinates (adjust if you're elsewhere)
    latitude = "51.5";
    longitude = "-0.1";
    # Color temperature settings
    temperature = {
      day = 6500;
      night = 3500;
    };
  };
}
