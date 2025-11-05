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

With `max-substitution-jobs = 64`, you have **64 packages** being queried simultaneously:

```
Job 1: hello     → cache.flakehub.com (5s timeout) → lewisflude.cachix.org (0.1s) = 5.1s
Job 2: git       → cache.flakehub.com (5s timeout) → lewisflude.cachix.org (0.1s) = 5.1s
Job 3: curl      → cache.flakehub.com (5s timeout) → lewisflude.cachix.org (0.1s) = 5.1s
...
Job 64: vim      → cache.flakehub.com (5s timeout) → lewisflude.cachix.org (0.1s) = 5.1s
```

**Total delay:** 64 jobs × 5 seconds = **320 seconds (5.3 minutes)** of wasted time!

## Cache Order Matters

Your `flake.nix` correctly orders caches:

```nix
extra-substituters = [
  "https://lewisflude.cachix.org"  # Personal cache - FIRST (fastest)
  "https://nix-community.cachix.org"  # Second
  "https://nixpkgs-wayland.cachix.org"  # Third
  # ... more caches
]
```

**Why this matters:**

- Most packages are found in the first cache
- Failed caches should be removed, not just reordered
- If a cache is unreachable, it will always cause delays regardless of position

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
4. **Order matters:** First cache is checked first, so put fastest/most reliable first
5. **Remove failed caches:** Better than reordering - eliminates delays entirely
6. **Parallel jobs multiply delays:** 64 jobs × 5s timeout = major delay

## Best Practices

✅ **Do:**

- Put your personal/fastest cache first
- Remove unreachable or failed caches entirely
- Keep `connect-timeout` low (5s is good) for faster failure detection
- Use `narinfo-cache-negative-ttl = 1` to avoid repeated queries

❌ **Don't:**

- Keep failed caches "just in case" (they cause delays)
- Put slow/unreliable caches first
- Set timeout too high (wastes time on failures)
- Ignore cache connection errors (they compound with parallel jobs)
