# Crash recovery and post-mortem reporting - Dendritic Pattern
#
# Jupiter's failure mode is not "it crashes", it is "it crashes and then sits
# there". Boot -3 ended 2026-08-09 00:42 and the next boot is 2026-08-11 10:13:
# ~57 hours of downtime waiting for a human to reach the power button. This
# module closes two gaps behind that: nothing turns a wedged kernel into a
# reboot, and nothing tells anyone it happened.
#
# What the crash dumps actually say (read 2026-08-11 from
# /var/lib/systemd/pstore, 96 archived events, efi_pstore backend):
#
#   BUG: Bad page state in process chrome  pfn:524cea
#   WARNING: CPU: 12 PID: 4311 at mm/vmscan.c:3337 get_pte_pfn.isra.0+0xcc/0xe0
#   BUG: Bad page map in process .qbittorrent-no  pte:800ffffad3cad435
#   Oops: Bad pagetable: 000d [#1] .. [#4] PREEMPT SMP NOPTI
#
# Four Oopses on 2026-08-08 (12:11 -> 15:28), plus a page-reclaim WARNING in
# core mm. Every corrupt PTE shares the `800ffffa` prefix — 800ffffad3cad435,
# 800ffffae6ffd435, 800ffffad57ed465, 800ffffae776d4e5 — i.e. identical top bits
# of the PFN field across four faults on different days. That is a structured
# fault, not random DRAM bit-flips, and it corroborates the existing diagnosis:
# FUSE page-cache mmap on the mergerfs /mnt/storage pool, addressed 2026-08-11
# with `cache.files=off` in hosts/jupiter/hardware.nix.
#
# Caveat worth keeping in view: one of the four is `Bad page state in process
# chrome`, which is not obviously a /mnt/storage mmap. It may be downstream of
# the same poisoned PFNs, or it may be a second cause. The corrected L2 icache
# MCE on 2026-08-11 keeps a hardware contribution on the table without being
# evidence for it.
#
# This module was originally about *surviving and reporting* crashes, not
# preventing them — prevention was the mergerfs change, and the reporter below
# is how we found out it was not enough. Section 3 is the one exception, added
# 2026-08-23 once the whole pstore corpus was finally read end to end: it is a
# prevention knob, and it lives here because crash policy should be readable in
# one place.
_: {
  flake.modules.nixos.crashRecovery =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # ─────────────────────────────────────────────────────────────────────
      # 1. Turn a wedged kernel into a reboot
      # ─────────────────────────────────────────────────────────────────────
      #
      # `kernel.panic = 30` (below) only helps once something
      # has actually panicked. Nothing here had: panic_on_oops defaulted to 0,
      # so every Oops above killed the faulting task and left the box running
      # with corrupt page tables until it fully hung. Every crash in this host's
      # history is a BUG/Oops, never a clean panic — which is precisely why the
      # existing auto-reboot never fired.
      #
      # Tradeoff, stated plainly: on a day like 2026-08-08 this reboots the
      # machine four times in five hours instead of limping. That is the better
      # outcome — each reboot is ~30s and writes a pstore record, whereas
      # limping cost 57 hours and risks writing corrupt pages to a pool that
      # has no redundancy.
      #
      # hardlockup_panic needs the NMI watchdog, which is already on
      # (kernel.nmi_watchdog = 1, verified 2026-08-11). It converts a true
      # CPU-stuck-with-interrupts-off lockup into a panic that can still reach
      # pstore, rather than a silent freeze that only the hardware watchdog
      # below can clear.
      #
      # Deliberately NOT set here:
      #   softlockup_panic - busy ZFS/mergerfs I/O legitimately stalls tasks
      #                      past the soft-lockup threshold; this would reboot a
      #                      healthy box mid-scrub.
      #
      # hung_task_panic came from the ZFS module originally: on 2026-06-21 a
      # `zfs list` (run by the frequent auto-snapshot timer) hit an OpenZFS
      # spl_panic in fnvlist_pack; the thread died holding ZFS locks, txg_sync
      # and others blocked 491s+, and the box stayed frozen ~28h until a manual
      # reboot. Panic on a task hung > 300s so a recurrence self-recovers in
      # minutes. 300s (not the 120s default) tolerates transient I/O stalls; if
      # a disk's SATA link is flaky this could still trigger an unwanted reboot.
      # It lives here rather than in zfs.nix because none of these are
      # ZFS-specific and crash policy should be readable in one place.
      boot.kernel.sysctl = {
        "kernel.panic_on_oops" = 1;
        "kernel.hardlockup_panic" = 1;
        "kernel.hung_task_timeout_secs" = 300;
        "kernel.hung_task_panic" = 1;
        "kernel.panic" = 30;
      };

      # ─────────────────────────────────────────────────────────────────────
      # 2. Hardware watchdog - the only thing that clears a true hard lockup
      # ─────────────────────────────────────────────────────────────────────
      #
      # Once the kernel is genuinely stuck, no software can reboot it. The
      # board's iTCO watchdog can. /sys/class/watchdog/watchdog0 exists
      # (identity: iTCO_wdt) but read `state: inactive` on 2026-08-11 — nothing
      # was petting it, so it has never once helped.
      #
      # 60s rather than the driver's 30s default: systemd only fails to ping
      # when the whole manager is wedged, and the TCO timer may require two
      # expirations before it actually asserts reset, so the effective window
      # is up to ~2x this. Do not stopwatch a test reset and conclude it is
      # broken when it takes longer than 60s.
      #
      # No RuntimeWatchdogPreGovernor: this chip does not support pretimeout.
      # `cat /sys/class/watchdog/watchdog0/options` reports 0x8180
      # (KEEPALIVEPING | MAGICCLOSE | SETTIMEOUT); the 0x0200 WDIOF_PRETIMEOUT
      # bit is absent. hardlockup_panic above is how we get a capturable oops
      # instead.
      #
      # RebootWatchdogSec is generous because this host's shutdown path unmounts
      # mergerfs over two 14TB XFS disks and exports a ZFS pool; a tight value
      # would reset mid-unmount and manufacture the unclean shutdowns we are
      # trying to avoid.
      #
      # Verify after switching (nowayout=0 here, so the watchdog stops on close
      # and this is safe to poke on a live pool):
      #   cat /sys/class/watchdog/watchdog0/state   # must read: active
      # RuntimeWatchdogSec is 10min, not 60s. At 60s the iTCO resets the box if
      # userspace fails to ping for a single minute — on a host that runs ZFS
      # scrubs and mergerfs over two 14TB disks, an ordinary I/O stall clears
      # that bar. The 2026-08-11 20:52:50 outage fits: journal stops mid-line,
      # no shutdown sequence, and — decisively — NO pstore record despite
      # hardlockup_panic=1 above, which is what a genuine NMI-detectable lockup
      # would have produced. An external reset writes nothing anywhere. That
      # event landed 3h25m after this module first armed the watchdog at 60s.
      # 10min still catches a real hang while sitting far above any plausible
      # I/O stall.
      systemd.settings.Manager = {
        RuntimeWatchdogSec = "10min";
        RebootWatchdogSec = "10min";
      };

      # ─────────────────────────────────────────────────────────────────────
      # 3. Cap CPU frequency — the one knob that slows the actual fault
      # ─────────────────────────────────────────────────────────────────────
      #
      # Reading all ~70 pstore records at once on 2026-08-22 changed the
      # diagnosis. Individually each crash looked like a software bug and was
      # filed as one; together they are ~40 *distinct* faulting RIPs spread
      # across unrelated subsystems (nvidia, zram, the scheduler, VFS, page
      # cache, slab, memcg accounting, coredump). ZFS accounts for ~6 of them,
      # which is why every ZFS-version fix here was followed by more crashes
      # somewhere else. Three findings settle it: the kernel's own linked-list
      # corruption detector (__list_add_valid_or_report) fired ~12 times, one
      # usercopy_abort, and several records where RIP is garbage — 0x0, 0x81,
      # and once a heap address being executed. Software does not set RIP to
      # 0x81. Crash-days/month then accelerated: Jun 3, Jul 12, Aug 8-in-23.
      #
      # That is an i9-13900K in the Raptor Lake Vmin-shift population,
      # corroborated by the corrected L2 icache MCE of 2026-08-11. Microcode is
      # already 0x137 (early-loaded over the board's 0x12b), but microcode only
      # stops *further* degradation — a part that has already shifted stays
      # shifted. The real fix is an RMA under Intel's extended 5-year warranty.
      #
      # The direction of the workaround is counterintuitive and easy to get
      # backwards. Vmin shift means the core now needs *more* voltage than it
      # used to, so an undervolt makes it worse, and the crashes cluster at idle
      # and light load rather than under stress. But adding voltage accelerates
      # the damage. Lowering the *frequency* is the only lever that helps both
      # ways at once: it drops the required Vmin and the requested VID together.
      # Do not reach for intel-undervolt here — MSR 0x150 is locked on desktop
      # RPL and it is the wrong direction regardless.
      #
      # Why tmpfiles rather than a service or a kernel parameter: per the
      # kernel's intel_pstate documentation, max_perf_pct is a sysfs attribute
      # with no command-line equivalent, and it resets to 100 on every boot (the
      # only related parameter, intel_pstate=per_cpu_perf_limits, *removes* the
      # global attribute instead of setting it). There is no NixOS option for
      # it. tmpfiles.d(5)'s `w` type — "write the argument parameter to a file,
      # if the file exists" — is the documented mechanism for exactly this, and
      # its own manual page uses a /proc/sys write as the example. It also
      # re-applies on `nixos-rebuild switch`, not just at boot, which a
      # boot-time oneshot would not.
      #
      # 86% of maximum turbo, i.e. roughly 5.8GHz -> ~5.0GHz on the P-cores.
      # Chosen to be a meaningful step down while leaving the machine fast
      # enough to not notice during normal desktop and transcode work; if
      # crashes continue, lower it further before concluding it did not help.
      #
      # Plain `w` (not `w-`): the path is guaranteed to exist on this host, and
      # if intel_pstate ever stops loading, a visible activation failure is the
      # correct outcome for a mitigation this load-bearing — silence would let
      # the box run uncapped without anyone noticing.
      #
      # Verify after switching:
      #   cat /sys/devices/system/cpu/intel_pstate/max_perf_pct   # must read: 86
      #
      # This is a holding action, not a repair. It buys uptime until the CPU is
      # replaced; it does not undo degradation that has already happened.
      systemd.tmpfiles.settings."10-rpl-vmin-cap" = {
        "/sys/devices/system/cpu/intel_pstate/max_perf_pct"."w".argument = "86";
      };

      # Coredumps earn their keep here — the 2026-08-23 01:39 V8 abort in
      # homarr's Next.js render worker, and the Cleanuparr/Radarr/Lidarr SIGSEGV
      # cluster of 2026-08-17, are the evidence that the faults span unrelated
      # runtimes. Keep collecting them. Unbounded, though, they are a liability
      # on this host: /var/lib/systemd/coredump had reached 3.2G by 2026-08-23,
      # and zstd-compressing a multi-gigabyte node or CoreCLR heap is a heavy
      # all-core, memory-pressuring job that fires exactly when the machine is
      # already misbehaving. Cap the per-process work and the total footprint;
      # the backtrace systemd writes to the journal survives either way, and
      # that is the part the crash report above actually reads.
      systemd.coredump.settings.Coredump = {
        ProcessSizeMax = "2G";
        ExternalSizeMax = "2G";
        MaxUse = "2G";
        KeepFree = "20G";
      };

      # ─────────────────────────────────────────────────────────────────────
      # 4. Say something when it happens
      # ─────────────────────────────────────────────────────────────────────
      #
      # The forensics layer already worked and nobody knew: 96 pstore records
      # had accumulated unread, including the four that identify the bug above.
      # An unread crash dump is worth almost nothing, so this reports at boot
      # through the same fan-out smartd and ZED use.
      #
      # Clean shutdowns log a "Reached target ..." shutdown marker in the
      # journal. Its *absence* in the previous boot is the crash signal — more
      # reliable than the watchdog's bootstatus, which reads 0 on this board
      # regardless of what happened.
      #
      # Reporting only on crash (rather than every boot) is deliberate: an alert
      # that arrives after every reboot gets ignored, and this one needs to be
      # read.
      systemd.services.crash-report = {
        description = "Report an unclean shutdown and any new crash dumps";

        # home-assistant is ordered-after but deliberately not wanted: this
        # reporter must never be the reason HA starts, and on a host without HA
        # the ordering is simply ignored. It exists because the 2026-08-14
        # 12:55 hang produced a report at 12:57:17 that died with `curl: (7)
        # Failed to connect to 127.0.0.1:8123` — HA had not started yet.
        #
        # Ordering alone does not fix that: the unit reports "started" well
        # before the API binds. The retry loop in alerts.nix covers the
        # remaining gap. Both are needed — this removes the bulk of the wait,
        # the retry absorbs what is left.
        after = [
          "systemd-pstore.service"
          "home-assistant.service"
        ];
        wants = [ "systemd-pstore.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "crash-report";
        };

        script = ''
          set -u
          state=/var/lib/crash-report
          pstore=/var/lib/systemd/pstore
          notify=${config.alerts.notify}/bin/system-alert

          # ── Was the previous boot clean? ──
          # -b -1 fails outright when there is no previous boot (first boot after
          # install, or a rotated journal); treat that as "nothing to report"
          # rather than crying crash.
          unclean=0
          if journalctl -b -1 --no-pager -o cat >/dev/null 2>&1; then
            if ! journalctl -b -1 --no-pager -o cat 2>/dev/null \
                 | grep -Eq 'Reached target (Shutdown|Final Step|Power-Off|Reboot)'; then
              unclean=1
            fi
          fi

          # ── Any pstore records we have not reported before? ──
          # Directory names are unix timestamps, so a numeric compare against the
          # high-water mark identifies new ones without tracking a list.
          # First run adopts whatever is already on disk as the baseline rather
          # than reporting it. There are 96 historical records here as of
          # 2026-08-11; announcing all of them at once would bury the one that
          # matters and train us to ignore the alert. History stays readable in
          # $pstore for anyone who goes looking.
          first_run=0
          seen=0
          if [ -r "$state/pstore-seen" ]; then
            seen="$(cat "$state/pstore-seen")"
          else
            first_run=1
          fi
          newest="$seen"
          new_records=""
          if [ -d "$pstore" ]; then
            for d in "$pstore"/*; do
              [ -d "$d" ] || continue
              n="$(basename "$d")"
              case "$n" in ''' | *[!0-9]*) continue ;; esac
              if [ "$n" -gt "$seen" ]; then
                new_records="$new_records $n"
                # Not `[ .. ] && newest=$n`: NixOS job scripts run under `sh -e`,
                # where a trailing false test would abort the whole reporter.
                if [ "$n" -gt "$newest" ]; then
                  newest="$n"
                fi
              fi
            done
          fi

          # Record the high-water mark unconditionally, so a delivery failure
          # cannot turn into the same alert repeating on every boot forever.
          echo "$newest" > "$state/pstore-seen"

          if [ "$first_run" -eq 1 ]; then
            echo "crash-report: baseline set at $newest, $(echo "$new_records" | wc -w) existing records adopted"
            new_records=""
          fi

          if [ "$unclean" -eq 0 ] && [ -z "$new_records" ]; then
            echo "crash-report: previous shutdown was clean, no new crash dumps"
            exit 0
          fi

          {
            if [ "$unclean" -eq 1 ]; then
              echo "Previous boot ended WITHOUT a clean shutdown marker."
            else
              echo "Previous boot shut down cleanly, but new crash dumps were found."
            fi
            echo

            if [ -n "$new_records" ]; then
              echo "New crash dumps in $pstore:$new_records"
              echo
              # What identifies a fault is the RIP and the call trace, not the
              # BUG: line — "NULL pointer dereference" alone names no function
              # and is not actionable. The rest of a dmesg record is pages of
              # module lists nobody reads in a notification, so this takes the
              # fault lines only. Full records stay on disk for follow-up.
              #
              # Read *only* the reassembled dmesg.txt. systemd-pstore walks the
              # raw dmesg-efi_pstore-* fragments in reverse order and stitches
              # them into that one file; the fragments themselves each begin
              # with an "Oops#1 Part12" chunk header. A recursive grep over the
              # record directory matches those headers too, and because '#'
              # (0x23) sorts before ':' (0x3a) they crowded out the real
              # "Oops: Oops: 0002" line — the 2026-08-23 report reached us as
              # four Part headers and no backtrace, which is what prompted this.
              #
              # Restricting find to dmesg.txt was NOT sufficient: systemd-pstore
              # copies the chunk headers into the reassembled file too, so the
              # 12:12 and 13:24 reports on 2026-08-23 still arrived as "Oops#1
              # Part1 / Part10 / Part11 / Part12" and no trace. Drop the headers
              # explicitly. Note also that a record can hold both 001/ and 002/
              # subdirectories (two panics in one death), so find legitimately
              # concatenates more than one dmesg.txt per record.
              #
              # No sort -u: these lines are a stack, and order is the meaning.
              for n in $new_records; do
                echo "--- $n ---"
                find "$pstore/$n" -name dmesg.txt -exec \
                  grep -hE 'BUG:|Oops:|WARNING:|general protection fault|RIP:|Call Trace|^ [a-z_0-9]+\+0x' {} + \
                  2>/dev/null \
                  | grep -v '^Oops#[0-9]* Part[0-9]*$' \
                  | head -25 || true
                echo
              done
            else
              echo "No new pstore records — a hard lockup or power loss that never"
              echo "reached the oops path. Check the tail of the previous boot:"
              echo "  journalctl -b -1 -e"
            fi

            # rasdaemon is already recording; surface it here because a
            # correlated MCE is the difference between "kernel bug" and
            # "hardware is failing", and that changes what to do next.
            if command -v ras-mc-ctl >/dev/null 2>&1; then
              echo "Recent hardware errors (ras-mc-ctl):"
              ras-mc-ctl --errors 2>/dev/null | head -20 || true
            fi
          } | $notify -s "Jupiter restarted after an unclean shutdown"
        '';

        path = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.systemd
        ]
        ++ lib.optional config.hardware.rasdaemon.enable config.hardware.rasdaemon.package;
      };

      # If the reporter itself dies, that must not be silent — it is the thing
      # standing between a crash and anyone knowing about it.
      systemd.services.crash-report.onFailure = [ "alert@%n.service" ];
    };
}
