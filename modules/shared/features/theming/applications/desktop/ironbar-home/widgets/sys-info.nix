_: {
  type = "sys_info";
  class = "sys-info";
  format = [
    # Clean format: icon + value, no % clutter
    " {cpu_percent}"
    " {memory_percent}"
  ];
  tooltip = "CPU: {cpu_percent}% | Memory: {memory_used_gb}GB / {memory_total_gb}GB ({memory_percent}%)";
  interval = 2000;
}
