# Manual qBittorrent Interface Binding (Quick Test)

**Use this if you want to test interface binding immediately without rebuilding NixOS.**

## Method 1: Via WebUI (Easiest)

1. **Open qBittorrent WebUI:**

   ```
   http://192.168.15.1:8080/
   ```

2. **Navigate to Settings:**
   - Click **Options** (gear icon) or go to **Tools > Options**

3. **Go to Advanced:**
   - Click **Advanced** in the left sidebar

4. **Set Network Interface:**
   - Find **"Network Interface"** setting
   - Change from **"Any interface"** to **`qbittor0`**
   - Click **Apply** or **OK**

5. **Restart qBittorrent:**

   ```bash
   sudo systemctl restart qbittorrent
   ```

## Method 2: Via Config File (Persistent until rebuild)

1. **Edit qBittorrent config:**

   ```bash
   sudo nano /var/lib/qBittorrent/config/qBittorrent.conf
   ```

2. **Find `[BitTorrent]` section and add/modify:**

   ```ini
   [BitTorrent]
   Session\InterfaceName=qbittor0
   ```

3. **Save and restart:**

   ```bash
   sudo systemctl restart qbittorrent
   ```

4. **Verify it worked:**

   ```bash
   sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep InterfaceName
   # Should show: Session\InterfaceName=qbittor0
   ```

## Verification

After setting the interface:

1. **Check in WebUI:**
   - Options > Advanced > Network Interface
   - Should show `qbittor0` (not "Any interface")

2. **Check config file:**

   ```bash
   sudo cat /var/lib/qBittorrent/config/qBittorrent.conf | grep InterfaceName
   ```

3. **Test UDP trackers:**
   - Check if UDP trackers still timeout
   - They should now work (or show different behavior)

## Important Notes

⚠️ **Manual changes will be overwritten** when you rebuild NixOS configuration.

✅ **Permanent solution:** After testing, rebuild your NixOS system:

```bash
sudo nh os switch
```

This will apply the configuration change we made to `qbittorrent-standard.nix`, which sets `InterfaceName = "qbittor0"` automatically when VPN is enabled.
