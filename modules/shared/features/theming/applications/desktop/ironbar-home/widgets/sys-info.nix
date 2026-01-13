_: {
  type = "sys_info";
  class = "sys-info";
  format = [
    # UX: Simplified format - icons convey meaning, numbers provide data
    " {cpu_percent}"
    " {memory_percent}"
  ];
  tooltip = "CPU: {cpu_percent}% | Memory: {memory_used_gb}GB / {memory_total_gb}GB";
  interval = 2000;
}
