# How Cache Connection Errors Affect Builds

## Overview

When a binary cache is unreachable or returns errors, it can significantly impact build performance, even if Nix eventually falls back to building from source or using other caches.

## Impact Mechanisms

### 1. **Timeout Delays**

**Current Configuration:**

- `connect-timeout = 5` seconds
- `http-connections = 64` (parallel connections)
- `max-substitution-jobs = 64` (concurrent substitution jobs)

**What Happens:**

- For each package, Nix queries **all** substituters in order
- If `cache.flakehub.com` is first in the list and fails, Nix waits up to 5 seconds per query before trying the next cache
- With 64 parallel substitution jobs, this can mean **64 simultaneous failed connections** waiting 5 seconds each

**Impact:**

- **64 × 5 seconds = up to 320 seconds (5.3 minutes)** of wasted time on timeout delays
- Even if only 10% of queries hit the failed cache first, that's still ~32 seconds of delays

### 2. **Sequential Cache Querying**

When Nix queries substituters, it typically checks them in order:

```
1. Try cache.flakehub.com → 5s timeout → FAIL
2. Try lewisflude.cachix.org → SUCCESS (or try next)
3. Try nix-community.cachix.org → SUCCESS (or try next)
...
```

**With 64 parallel jobs each querying caches sequentially:**

- Each job waits for the failed cache timeout before moving to the next
- This multiplies the delay across all parallel jobs

**Impact:**

- Builds that should take seconds can take minutes
- Large builds with thousands of packages compound the delay

### 3. **Connection Pool Exhaustion**

With `http-connections = 64`, Nix maintains a pool of HTTP connections:

```
64 total connections
├─ 32 connections trying cache.flakehub.com (all failing)
├─ 20 connections to working caches (succeeding)
└─ 12 connections idle/queued
```

**Problem:**

- Failed connections don't immediately release back to the pool
- They hold connections until timeout completes
- This reduces available connections for working caches

**Impact:**

- Even working caches become slower because fewer connections are available
- Throughput decreases despite parallel configuration

### 4. **Download Thread Shutdown Errors**

From your logs, we saw:

```
error: cannot enqueue download request because the download thread is shutting down
```

**What Happens:**

- When cache errors accumulate, Nix's download manager can get into a bad state
- This causes the download thread to shut down
- All pending downloads get paused, not just from the failed cache

**Impact:**

- **This is what you experienced:** 532 builds paused, 3014 downloads paused
- The entire substitution system stalls, not just the failed cache
- Requires daemon restart to recover

### 5. **Cache TTL Negative Lookups**

**Configuration:**

- `narinfo-cache-negative-ttl = 1` second

**What Happens:**

- When a cache query fails, Nix caches the "not found" result for 1 second
- But if the cache is completely unreachable, it keeps trying
- Each failed package gets queried again after the TTL expires

**Impact:**

- Repeated failed queries for the same packages
- Wasted network requests and CPU cycles

## Real-World Example

**Scenario:** Building 1000 packages with FlakeHub cache in the list

**Without Failed Cache:**

- Average query time: 0.1s per cache
- 3 caches checked = 0.3s per package
- 1000 packages × 0.3s = 300s total (5 minutes)
- With 64 parallel jobs: ~300s / 64 = ~5 seconds

**With Failed Cache First:**

- First cache timeout: 5s per package
- Then 2 working caches: 0.2s each
- Total: 5.2s per package
- 1000 packages × 5.2s = 5200s (87 minutes)
- With 64 parallel jobs: ~5200s / 64 = ~81 seconds

**Time Added:** ~76 seconds minimum, potentially much more if connection pool gets exhausted

## Your Specific Case

From your build output:

- **532 builds paused**
- **3014 downloads paused**
- **Time elapsed:** 4m33s at the time of the error

**Likely Sequence:**

1. Multiple packages tried `cache.flakehub.com` first
2. All connections timed out (5s each)
3. Download thread started shutting down due to errors
4. All pending operations got paused
5. Build effectively stalled until daemon restart

**Without the failed cache:**

- Those 532 builds would have immediately queried working caches
- Downloads would have proceeded normally
- Build would have completed much faster

## Solutions

### 1. Remove Failed Caches (Recommended)

- Removes timeout delays entirely
- No wasted connection attempts
- Faster builds immediately

### 2. Increase Timeout (Not Recommended)

- Would make failures take even longer
- Doesn't fix the root problem
- Wastes more time on failed connections

### 3. Reorder Caches (Partial Fix)

- Put working caches first
- Failed cache still causes delays (just later in the sequence)
- Better than nothing, but not ideal

### 4. Use `narinfo-cache-negative-ttl` (Already Configured)

- Your `narinfo-cache-negative-ttl = 1` helps
- But doesn't help if cache is completely unreachable (vs. just "not found")

## Best Practice

**Remove caches that:**

1. Require authentication (unless you have credentials)
2. Are consistently unreachable
3. Return errors (HTTP 400, 403, 500, etc.)
4. Are documented as deprecated/removed

**Keep caches that:**

1. Are publicly accessible
2. Respond quickly (< 1 second)
3. Have good coverage for your packages
4. Are actively maintained

## Your Configuration

Your `flake.nix` already documents:

```nix
# Note: FlakeHub cache removed - requires authentication and isn't needed
# FlakeHub flakes are downloaded from the API, not the binary cache
```

But it's still in `/etc/nix/nix.conf` from Determinate Nix. Removing it will:

- Eliminate connection timeout delays
- Prevent download thread shutdown errors
- Speed up builds significantly
- Align your system config with your flake config
