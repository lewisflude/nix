# Battery widget using UPower
# Only included on hosts with battery (laptops)
_: {
  type = "upower";
  class = "battery";
  format = "{percentage}%";
  # Show icon based on charge level
  show_if = "upower"; # Only show if UPower reports a battery
}
