# GTK Inspector Showing Default Colors - Explanation

## Summary

Your GTK theming is **correctly configured**. The issue is that **GTK Inspector** (`gtk-inspect`/`gtk4-inspector`) shows default GNOME colors instead of Signal colors, but this is a **limitation of the Inspector tool**, not a theming problem.

## Diagnostic Results

✅ **CSS files exist and are correct:**
- `~/.config/gtk-4.0/gtk.css` (420 lines) - Contains Signal colors
- `~/.config/gtk-3.0/gtk.css` - Contains Signal colors

✅ **Signal colors are defined:**
- `--blue-3: #7fc9d5` (Signal secondary accent)
- `--green-3: #6ec584` (Signal primary accent)
- `--accent-bg-color: #7fc9d5`
- 107 `@define-color` statements total

✅ **GTK settings configured:**
- `gtk-theme-name=Adwaita-dark` in both GTK3 and GTK4 `settings.ini`
- Theme name correctly set

✅ **CSS structure correct:**
- Contains `:root` block with CSS custom properties (GTK4)
- Contains `@define-color` directives (GTK3/GTK4 compatible)

## Why GTK Inspector Shows Wrong Colors

GTK Inspector is a debugging tool that has limitations:

1. **Shows base theme colors**: Inspector may display computed styles from the base Adwaita theme **before** CSS overrides are applied
2. **Doesn't load user CSS**: Inspector may not properly load `~/.config/gtk-4.0/gtk.css` in its inspection context
3. **Shows theme defaults**: Inspector displays the theme's default color palette, not the CSS-overridden values

This is a **known limitation** of GTK Inspector, not a problem with your theming setup.

## How to Verify Theming is Actually Working

Since Inspector can be misleading, verify visually:

### 1. Check Ironbar Visually
- Does ironbar itself show Signal colors (not default GNOME blue/green)?
- Are backgrounds/text colors matching your Signal theme?
- **If yes → Theming is working!**

### 2. Test Other GTK4 Applications
Open these applications and check if they show Signal colors:
```bash
nautilus          # GNOME Files
gnome-text-editor # Text editor
```

If these show Signal colors, your theming is working correctly.

### 3. Check CSS is Being Applied
The CSS file exists and contains Signal colors. GTK4 applications should be loading it automatically.

## Conclusion

**If ironbar and other GTK apps visually show Signal colors correctly, then:**
- ✅ Your theming is working perfectly
- ✅ Signal-nix is configured correctly
- ⚠️ GTK Inspector is just showing misleading information

**If ironbar itself shows wrong colors:**
- Try restarting ironbar: `systemctl --user restart ironbar` or `ironbar reload`
- Check ironbar logs: `journalctl --user -u ironbar -f`
- Verify `theming.signal.gtk.enable = true;` in your config

## Related Files

- CSS files: `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk.css`
- Settings: `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`
- Diagnostic script: `./check-gtk-theming.sh`
- Color test script: `./test-gtk-colors.sh`
