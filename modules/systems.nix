# Supported systems — limited to the architectures actually in use.
# Jupiter is x86_64-linux, Mercury is aarch64-darwin. Adding systems here
# exposes apps/devShells/formatter/packages for them and pays evaluation cost
# on every flake check, so we keep the list minimal.
_: {
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
