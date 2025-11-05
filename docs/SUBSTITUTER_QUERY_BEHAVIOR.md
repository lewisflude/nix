# How Nix Queries Substituters (Binary Caches)

## Sequential Querying (Not Parallel)

**Key Point:** Nix queries substituters **sequentially** (one after another), not in parallel.

## Query Process

For each package, Nix checks substituters **in order**:

```
Package: hello
├─ 1. Query cache.flakehub.com → Wait 5s timeout → FAIL ❌
├─ 2. Query lewisflude.cachix.org → Response 0.1s → SUCCESS ✅
└─ 3. Download from lewisflude.cachix.org
```

**Important:** Nix does **NOT** stop on failure. It continues to the next substituter.

## What Happens on Failure

### Scenario 1: Failed Cache First (Worst Case)

```
Package: hello
├─ 1. Query cache.flakehub.com → 5s timeout → FAIL ❌
├─ 2. Query lewisflude.cachix.org → 0.1s → SUCCESS ✅
└─ Total time: 5.1 seconds
```

**Problem:** Every package waits 5 seconds for the failed cache before trying the next one.

### Scenario 2: Failed Cache Last (Better)

```
Package: hello
├─ 1. Query lewisflude.cachix.org → 0.1s → SUCCESS ✅
└─ Total time: 0.1 seconds
```

**Better:** Never queries the failed cache because a working cache is found first.

### Scenario 3: All Caches Fail

```
Package: hello
├─ 1. Query cache.flakehub.com → 5s timeout → FAIL ❌
├─ 2. Query lewisflude.cachix.org → 5s timeout → FAIL ❌
├─ 3. Query nix-community.cachix.org → 5s timeout → FAIL ❌
└─ Build from source (if fallback = true)
```

**Total time:** 15 seconds of wasted time before building from source.

## Parallel Substitution Jobs

With `max-substitution-jobs = 128`, you have **128 packages** being queried simultaneously:

```
Job 1: hello     → nix-community.cachix.org (0.1s) = 0.1s ✅
Job 2: git       → nix-community.cachix.org (0.1s) = 0.1s ✅
Job 3: curl      → nix-community.cachix.org (0.1s) = 0.1s ✅
...
Job 128: vim     → nix-community.cachix.org (0.1s) = 0.1s ✅
```

**With proper priorities:** 128 jobs × 0.1 seconds = **12.8 seconds total** (much better!)

**Without priorities (worst case):** 128 jobs × 5 seconds = **640 seconds (10.7 minutes)** of wasted time!

## Cache Order Matters

Your `flake.nix` uses **priority parameters** to explicitly control cache query order:

```nix
extra-substituters = [
  "https://nix-community.cachix.org?priority=1"  # Highest priority (queried first)
  "https://lewisflude.cachix.org?priority=3"  # Personal cache - high priority
  "https://nixpkgs-wayland.cachix.org?priority=4"  # Medium priority
  # ... more caches with priority=5, priority=6, etc.
]
```

**How Priority Works:**

- **Lower numbers = higher priority** (queried first)
- Nix sorts caches by priority before querying
- This ensures reliable caches are always checked first, regardless of array order
- Prevents slow/unreliable caches from being queried first due to alphabetical sorting

**Why this matters:**

- Most packages are found in high-priority caches
- Failed caches should be removed, not just reordered
- If a cache is unreachable, it will always cause delays regardless of position
- Priority parameters provide explicit control over query order

**Reference**: [How to Optimise Substitutions in Nix](https://brianmcgee.uk/posts/2023/12/13/how-to-optimise-substitutions-in-nix/)

## Timeout Behavior

With `connect-timeout = 5`:

- Nix waits up to **5 seconds** for a connection to establish
- If connection fails (timeout, DNS error, network error), it moves to the next cache
- If connection succeeds but query fails (HTTP 404, 403, etc.), it moves to the next cache immediately

**Key Insight:** The timeout only applies to **establishing the connection**, not to the entire query. But if the connection can't be established (like with FlakeHub requiring auth), it waits the full 5 seconds.

## Cache TTL Impact

With `narinfo-cache-negative-ttl = 1`:

- If a cache says "not found" (HTTP 404), Nix caches that negative result for 1 second
- Prevents repeated queries to the same cache for the same package
- But doesn't help if the cache is completely unreachable (connection timeout)

## Why Removing Failed Caches Matters

### With Failed Cache

```
64 packages × 5s timeout = 320 seconds wasted
```

### Without Failed Cache

```
64 packages × 0.1s (first cache hit) = 6.4 seconds total
```

**Time saved:** ~314 seconds (5.2 minutes) per build cycle!

## Summary

1. **Sequential, not parallel:** Nix checks caches one after another
2. **Doesn't stop on failure:** Continues to next cache
3. **Waits for timeout:** Each failed cache causes a delay before trying the next
4. **Priority matters:** Use `?priority=xxx` parameters to control query order explicitly
5. **Remove failed caches:** Better than reordering - eliminates delays entirely
6. **Parallel jobs multiply delays:** 128 jobs × 5s timeout = major delay (but priorities minimize this)

## Best Practices

✅ **Do:**

- Use `?priority=xxx` parameters to explicitly control cache query order
- Set lower priority numbers for most reliable/fastest caches (priority=1, priority=2, etc.)
- Remove unreachable or failed caches entirely
- Keep `connect-timeout` low (5s is good) for faster failure detection
- Use `narinfo-cache-negative-ttl = 1` to avoid repeated queries
- Set `http-connections = 128` and `max-substitution-jobs = 128` for maximum parallelism

❌ **Don't:**

- Keep failed caches "just in case" (they cause delays)
- Put slow/unreliable caches at high priority (low numbers)
- Set timeout too high (wastes time on failures)
- Ignore cache connection errors (they compound with parallel jobs)
- Rely on array order alone - use priority parameters for explicit control
