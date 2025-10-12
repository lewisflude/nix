_: {
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
    permittedInsecurePackages = [
      "mbedtls-2.28.10"
    ];
  };
}
