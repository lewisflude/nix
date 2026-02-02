{
  imports = [
    # Aspects (dendritic feature modules)
    # All feature implementations are now in aspects/
    ../../aspects

    # Core system modules (not features)
    ./core
    ./hardware
    ./services
    ./development
    ./system
  ];
}
