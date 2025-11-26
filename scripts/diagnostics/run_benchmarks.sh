#!/usr/bin/env bash

# Script to run performance benchmarks.
# This script should be run inside a nix-shell with the required packages.

# Usage:
# nix-shell -p iperf3 ethtool mtr fio sysstat smartmontools hdparm stress-ng numactl linux-tools pciutils --run "./run_benchmarks.sh"
#
# Or, to enter the shell first:
# nix-shell -p iperf3 ethtool mtr fio sysstat smartmontools hdparm stress-ng numactl linux-tools pciutils
# [nix-shell:~]$ ./run_benchmarks.sh

RESULTS_FILE="performance_results.txt"
INTERFACE="eno2"
TARGET_SERVER="localhost" # Replace with a real server for accurate network tests

# --- Helper Functions ---
echo_section() {
    echo "========================================================================" | tee -a $RESULTS_FILE
    echo " $1" | tee -a $RESULTS_FILE
    echo "========================================================================" | tee -a $RESULTS_FILE
}

run_and_log() {
    echo "--- Running: $@ ---" | tee -a $RESULTS_FILE
    # shellcheck disable=SC2090
    "$@" >> $RESULTS_FILE 2>&1
    echo "" | tee -a $RESULTS_FILE
}

# --- Start of Script ---
# Clear previous results
rm -f $RESULTS_FILE
touch $RESULTS_FILE
echo "Performance Benchmark Results" | tee -a $RESULTS_FILE
echo "Date: $(date)" | tee -a $RESULTS_FILE
echo "---------------------------------" | tee -a $RESULTS_FILE

# --- Network Performance ---
echo_section "Network Performance"
run_and_log ss -s
run_and_log nstat -az
run_and_log ethtool "$INTERFACE"
run_and_log tc -s qdisc show dev "$INTERFACE"
echo "--- Running: iperf3 -c $TARGET_SERVER ---" | tee -a $RESULTS_FILE
echo "NOTE: iperf3 requires a server running on the target. Using localhost as a placeholder." | tee -a $RESULTS_FILE
run_and_log iperf3 -c "$TARGET_SERVER"
echo "--- Skipping: ping -c 100 -f $TARGET_SERVER ---" | tee -a $RESULTS_FILE
echo "NOTE: Flood ping requires sudo and is being skipped." | tee -a $RESULTS_FILE
# sudo ping -c 100 -f "$TARGET_SERVER" >> $RESULTS_FILE 2>&1
echo "" | tee -a $RESULTS_FILE
echo "--- Running: mtr $TARGET_SERVER ---" | tee -a $RESULTS_FILE
run_and_log mtr -n -c 10 --report "$TARGET_SERVER"

# --- Disk Performance ---
echo_section "Disk Performance"
run_and_log lsblk -t
# Find a real block device for testing that is not the root partition if possible
DISK_DEVICE=$(lsblk -o NAME,MOUNTPOINT -nr | grep -vE 'SWAP|boot' | awk 'NR==1{print "/dev/"$1}')
if [ -z "$DISK_DEVICE" ]; then
    DISK_DEVICE="/dev/nvme0n1" # Fallback
fi
echo "Using disk device: $DISK_DEVICE for smartctl and hdparm." | tee -a $RESULTS_FILE

run_and_log iostat -xz 1 5
echo "--- Skipping: smartctl -a $DISK_DEVICE ---" | tee -a $RESULTS_FILE
echo "NOTE: smartctl requires sudo and is being skipped." | tee -a $RESULTS_FILE
# sudo smartctl -a "$DISK_DEVICE" >> $RESULTS_FILE 2>&1
echo "" | tee -a $RESULTS_FILE
echo "--- Skipping: hdparm -tT $DISK_DEVICE ---" | tee -a $RESULTS_FILE
echo "NOTE: hdparm requires sudo and is being skipped." | tee -a $RESULTS_FILE
# sudo hdparm -tT "$DISK_DEVICE" >> $RESULTS_FILE 2>&1
echo "" | tee -a $RESULTS_FILE

echo_section "Disk I/O (fio)"
FIO_FILE="fio_test_file.tmp"
run_and_log fio --name=random-write --ioengine=libaio --iodepth=32 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=4 --runtime=60 --group_reporting --filename=$FIO_FILE
run_and_log fio --name=seq-read --ioengine=libaio --iodepth=32 --rw=read --bs=1m --direct=1 --size=1G --numjobs=1 --runtime=60 --group_reporting --filename=$FIO_FILE
rm -f $FIO_FILE

# --- Memory Performance ---
echo_section "Memory Performance"
run_and_log free -h
run_and_log cat /proc/meminfo
run_and_log vmstat -w 1 10
run_and_log numactl --hardware
run_and_log sysctl vm.swappiness
run_and_log sysctl vm.dirty_ratio
run_and_log cat /proc/sys/vm/zone_reclaim_mode
echo "--- Running: stress-ng (Memory) ---" | tee -a $RESULTS_FILE
run_and_log stress-ng --vm 4 --vm-bytes 80% --vm-method all --verify --timeout 60s --metrics-brief

# --- Hardware/CPU Checks ---
echo_section "Hardware Checks"
echo "--- Running: perf stat ---" | tee -a $RESULTS_FILE
run_and_log perf stat -e cycles,instructions,cache-references,cache-misses sleep 5
echo "--- Running: lspci (GPU) ---" | tee -a $RESULTS_FILE
run_and_log lspci -vv
echo "--- Running: CPU Info (P+E Cores) ---" | tee -a $RESULTS_FILE
run_and_log cat /proc/cpuinfo

echo "========================================================================" | tee -a $RESULTS_FILE
echo " Benchmark complete. Results saved to $RESULTS_FILE"
echo "========================================================================" | tee -a $RESULTS_FILE
