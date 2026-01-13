# Niri Animations Configuration
{
  ...
}:
{
  animations = {
    enable = true;
    slowdown = 1.0;
    workspace-switch = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
      };
    };
    window-movement = {
      enable = true;
      kind = {
        spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
      };
    };
  };
}
