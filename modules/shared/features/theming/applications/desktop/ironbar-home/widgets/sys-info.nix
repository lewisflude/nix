_: {
  type = "sys_info";
  class = "sys-info";
  format = [
    # Clear format with % signs for explicit meaning
    # Integer formatting prevents decimal aliasing issues
    "  {cpu_percent:.0f}%"
    "  {memory_percent:.0f}%"
  ];
  tooltip = "CPU: {cpu_percent:.0f}% | Memory: {memory_used_gb:.1f}GB / {memory_total_gb:.1f}GB ({memory_percent:.0f}%)";
  interval = 2000;
}
