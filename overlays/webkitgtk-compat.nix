# Compatibility overlay for webkitgtk removal
# webkitgtk was removed from nixpkgs and replaced with a throw; packages should use versioned variants
# This provides a temporary alias to maintain compatibility with packages that haven't been updated yet
final: _prev: {
  # Override the throw with an actual package - use webkitgtk_6_0 as the default
  webkitgtk = final.webkitgtk_6_0;
}
