# Quick WireGuard Status Check

## Simple Command

Run this command **as root**:

```bash
sudo ip netns exec qbt /nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg show qbt0
```

## Or Use the Helper Script

```bash
cd /home/lewis/.config/nix
sudo bash scripts/check-wg.sh
```

## What the Output Means

**If WireGuard is connected (working):**

```
interface: qbt0
  public key: <some-key>
  private key: (hidden)
  listening port: <port>

peer: YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=
  endpoint: 185.107.44.110:51820
  allowed ips: 0.0.0.0/0, ::/0
  latest handshake: 2 seconds ago    ← THIS IS KEY!
  transfer: 1.23 MiB received, 456 KiB sent
```

**If WireGuard is NOT connected:**

```
interface: qbt0
  public key: <some-key>
  private key: (hidden)
  listening port: <port>

peer: YgGdHIXeCQgBc4nXKJ4vct8S0fPqBpTgk4I8gh3uMEg=
  endpoint: 185.107.44.110:51820
  allowed ips: 0.0.0.0/0, ::/0
  ← NO handshake shown!
  transfer: 0 B received, 0 B sent
```

## If No Handshake

1. Restart services:

   ```bash
   sudo systemctl restart generate-qbt-wg-config.service
   sudo systemctl restart qbt.service
   ```

2. Wait 5-10 seconds for handshake

3. Check again:

   ```bash
   sudo ip netns exec qbt /nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg show qbt0
   ```

4. Check logs if still not working:

   ```bash
   sudo journalctl -u qbt.service -n 50 --no-pager
   ```

## Alternative: Find wg Command

If the path above doesn't work, find it:

```bash
find /nix/store -name "wg" -type f 2>/dev/null | grep wireguard | head -1
```

Then use that path:

```bash
WG_PATH=$(find /nix/store -name "wg" -type f 2>/dev/null | grep wireguard | head -1)
sudo ip netns exec qbt "$WG_PATH" show qbt0
```
