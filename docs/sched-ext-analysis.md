# sched-ext Analysis — AMD Ryzen AI 7 350 (Yoga)

## System Profile

- **CPU**: AMD Ryzen AI 7 350 w/ Radeon 860M (8C/16T, 1 socket, 1 NUMA node)
- **RAM**: 30 GiB
- **Kernel**: `7.0.12-201.fc44.x86_64` (sched_ext enabled)
- **OS**: Fedora 44 KDE
- **Form factor**: Laptop — efficiency is primary goal

## Topology Findings

The Ryzen AI 7 350 is a **hybrid architecture** (4× Zen 5 + 4× Zen 5c cores):

| CPU | Core | amd_pstate_prefcore_ranking | Classification |
|-----|------|----------------------------|----------------|
| 4,6,12,14 | Physical (best-binned) | 208 | Big (turbo) |
| 0,8 | Physical | 202 | Big |
| 2,10 | Physical | 196 | Big |
| 1,3,5,7,9,11,13,15 | SMT siblings | 135 | Little |

Ratio: 208/135 = 1.54× (exceeds 1.3× big.LITTLE threshold)

- `scaling_governor`: `powersave`
- `energy_performance_preference`: `balance_power`
- `cpu_capacity` sysfs: uniform 1024 (not useful)
- `amd_pstate` driver is active and providing per-core ranking

## Installed Packages

- `scx-scheds` 1.1.1 (terra)
- `scx-tools` 1.1.1 (terra) — provides `scxctl`
- `scx-manager` 1.15.10 (cachyos copr)

## Available Schedulers

```
/usr/bin/scx_bpfland   /usr/bin/scx_cosmos    /usr/bin/scx_flash
/usr/bin/scx_lavd      /usr/bin/scx_layered   /usr/bin/scx_rusty
/usr/bin/scx_rustland  /usr/bin/scx_tickless  /usr/bin/scx_beerland
/usr/bin/scx_cake      /usr/bin/scx_chaos     /usr/bin/scx_flow
/usr/bin/scx_p2dq      /usr/bin/scx_pandemonium
```

## Scheduler Analysis (from source: sched-ext/scx @ GitHub, commit 95ebd51)

### scx_bpfland — RECOMMENDED for efficiency

- **Official recommendation**: sched-ext team targets scx_bpfland for "laptops and desktops" (LPC2025)
- **AMD support**: Indirect via scx_utils topology — uses `amd_pstate_prefcore_ranking` as highest-priority capacity source. `powersave` mode restricts to Little cores (SMT siblings)
- **Frequency scaling**: `--cpufreq` enables closed-loop `scx_bpf_cpuperf_set()` driven by per-CPU utilization (EMA-smoothed). In powersave: locks to minimum frequency
- **Throttle injection**: `--throttle-us` injects forced idle cycles for battery savings
- **Idle QoS**: `--idle-resume-us` raises resume latency limit for deeper C-states
- **Production-ready**: Yes
- Source: scheds/rust/scx_bpfland/

| Flag | Default | Purpose |
|------|---------|---------|
| `-m` / `--primary-domain` | "auto" | powersave/performance/turbo/all/cpumask |
| `-f` / `--cpufreq` | false | Auto CPU freq scaling (schedutil only) |
| `-s` / `--slice-us` | 1000 | Max timeslice (µs) |
| `-t` / `--throttle-us` | 0 | Inject idle cycles (battery saving) |
| `-I` / `--idle-resume-us` | -1 | CPU idle QoS resume latency |
| `-T` / `--timely` | false | TIMELY delay-driven adaptive slices |

### scx_cosmos — Runner-up for battery life

- **Designed for**: General-purpose, lightweight, locality-preserving
- **Deferred wakeups**: Batches CPU wakeups into timer callbacks, reducing IPIs and keeping CPUs in deep C-states longer
- **Capacity-scaled time slices**: Scales vruntime by `cpu_capacity`, correctly handling hybrid topologies
- **NUMA**: Auto-disabled on single-node systems
- **Powersave**: `-m powersave -d -p 5000` restricts to Little cores
- **Note**: Had idle power regressions (issue #3283) — fixed with `-d` flag, now deprecated/default
- **Production-ready**: Yes
- Source: scheds/rust/scx_cosmos/

### scx_p2dq — Best AMD hardware exploitation

- **AMD prefcore support**: `--cpu-priority` flag uses kernel's `sched_core_priority` BPF helper (populated by amd-pstate CPPC). Preferred cores get first dibs on waking tasks via minheap
- **Full power controls**: EPP (`set_epp`), turbo enable/disable, uncore frequency, idle QoS
- **Hybrid support**: Full EAS (Energy-Aware Scheduling) with per-CPU energy cost model. Sched modes: Performance/Efficiency/Default
- **Production-ready**: Deployed at Meta, but AMD power features labeled "sort of work"
- Source: scheds/rust/scx_p2dq/

### scx_cake — Gaming-focused, interesting but not ideal for efficiency

- **Only scheduler with explicit `amd_pstate_prefcore_ranking` sysfs read** — but the data only activates Gate 2 scan order when `has_hybrid_cores` is true
- **CPUPERF steering was REMOVED** — previously boosted GAME tasks to 1024, throttled non-GAME to 768. Removed because it hurt loading threads and compositor
- **Battery profile**: Functionally identical to Legacy (4ms quantum, 200ms starvation) — DVFS claimed but non-functional
- **Production-ready**: Carries experimental label (framework-mandated), but code quality is production-grade
- Source: scheds/rust/scx_cake/

### scx_lavd

- Full power mode system (performance/balanced/powersave + autopilot/autopower)
- Core compaction in powersave: packs work onto few CPUs, letting others deep-idle
- No AMD-specific prefcore support — uses generic capacity/frequency observation
- Per-task CPU frequency scaling via `cpufreq_policy` kfunc
- Production-ready

### scx_flash

- EDF-based, throttle idle injection, idle QoS
- Primary domain "powersave" selects slowest CPUs
- Good for multimedia/real-time
- Production-ready

### scx_rustland

- All scheduling in userspace Rust — high overhead, not efficient
- Not recommended for laptops

### scx_tickless

- Server-oriented, requires `nohz_full` kernel parameter
- Not designed for latency-sensitive workloads
- Experimental

### scx_rusty, scx_layered

- Server/data-center focused
- Minimal power management features
- Not recommended for laptop efficiency

## Recommendation: scx_bpfland

**Start with:**
```bash
sudo scxctl start scx_bpfland powersave
```

**Manual (full control):**
```bash
sudo scx_bpfland -m powersave --cpufreq -I 10000 -t 10000 -s 10000 -S 1000
```

**If you want AMD hardware exploitation (CPPC/prefcore):**
```bash
sudo scxctl start scx_p2dq powersave
```
or
```bash
sudo scx_p2dq --cpu-priority --sched-mode efficiency --enable-eas --turbo=false
```

## References

- Repo: https://github.com/sched-ext/scx (clone at `/tmp/scx-repo`)
- sched-ext docs: https://sched-ext.com/
- CachyOS sched-ext guide: https://wiki.cachyos.org/configuration/sched-ext/
- Kernel docs: https://docs.kernel.org/scheduler/sched-ext.html
- LPC2025 sched-ext status: https://lpc.events/event/19/contributions/2035/

Analysis date: 2026-06-23
