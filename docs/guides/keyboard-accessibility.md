# Keyboard Configuration - Accessibility Guide

**Making ergonomic keyboard setups accessible to all users**

---

## Overview

This guide addresses accessibility considerations for the v2.0 Ergonomic Hybrid keyboard configuration. While our default setup provides significant ergonomic benefits for many users, we recognize that one size doesn't fit all.

**Goal:** Provide alternatives and modifications for users with motor, cognitive, or visual disabilities.

---

## Motor Disabilities

### Issue: Difficulty Holding Modifier Keys

**Challenge:** Users with limited hand strength, tremors, or single-hand operation may struggle with hold-based modifiers.

#### Solution 1: Sticky Keys (Toggle Instead of Hold)

**NixOS (keyd):**
```nix
# modules/nixos/system/keyd.nix
main = {
  # Change from hold to toggle (one-shot)
  capslock = "oneshot(leftmeta)";  # Press once, stays active until next key
  
  # Or use toggle mode
  # capslock = "toggle(leftmeta)";  # Press to enable, press again to disable
};
```

**macOS (Karabiner):**
```nix
# modules/darwin/karabiner.nix
# Add sticky keys via system preferences:
# System Settings → Accessibility → Keyboard → Sticky Keys
```

**Benefits:**
- No need to hold keys simultaneously
- Reduces hand strain
- Enables single-hand operation

#### Solution 2: Increase Tap/Hold Threshold

**For users with tremors or slower movements:**

**NixOS:**
```nix
# modules/nixos/system/keyd.nix
global = {
  overload_tap_timeout = 500;  # Increase from 200ms to 500ms
};
```

**macOS:**
```nix
# modules/darwin/karabiner.nix
parameters = {
  "basic.to_if_alone_timeout_milliseconds" = 500;
};
```

#### Solution 3: Use External Foot Pedal

**Hardware solution for severe motor limitations:**

```bash
# Map foot pedal to Super/Command key
# Works with any USB foot pedal (e.g., VEC Infinity series)

# NixOS (using evdev)
sudo evtest /dev/input/eventX  # Find pedal device
# Map in keyd: pedal_key = "leftmeta"

# macOS (using Karabiner)
# Karabiner detects USB devices automatically
# Map via GUI: Foot Pedal → Command
```

**Benefits:**
- Completely hands-free modifier
- No finger movement required
- Preserves hand position for typing

---

## Cognitive Disabilities

### Issue: Navigation Layer Adds Mental Load

**Challenge:** Users with memory impairments, attention deficits, or cognitive processing disorders may find layer switching overwhelming.

#### Solution 1: Simplified Single-Layer Config

**Start with Caps→ Super only, skip navigation layer:**

**NixOS:**
```nix
# modules/nixos/system/keyd.nix
main = {
  capslock = "overload(leftmeta, esc)";  # Only this
  f13 = "leftmeta";                       # And this
  # rightalt = "layer(nav)";              # DISABLE navigation layer
};
```

**Benefits:**
- Fewer things to remember
- Reduced cognitive load
- Can add navigation layer later when comfortable

#### Solution 2: Visual Overlay/Indicator

**Show current layer state:**

**NixOS (using waybar):**
```nix
# Add layer indicator to status bar
# Shows "NAV" when Right Alt is held
```

**macOS (using Keyboard Maestro):**
```bash
# Display on-screen indicator when layer active
brew install --cask keyboard-maestro
```

#### Solution 3: Physical Cheat Sheet

**Low-tech, highly effective:**

```markdown
Print this and place near keyboard:

┌──────────────────────────────┐
│ CAPS HOLD = Super/Command    │
│ CAPS TAP = Escape            │
│                              │
│ Right Alt + H = ←            │
│ Right Alt + J = ↓            │
│ Right Alt + K = ↑            │
│ Right Alt + L = →            │
└──────────────────────────────┘
```

---

## Visual Impairments

### Issue: Screen Reader Compatibility

**Challenge:** Some shortcuts may conflict with screen reader commands (Orca, NVDA, JAWS).

#### Solution: Test and Remap Conflicts

**Screen reader users should:**

1. **Test configuration with your screen reader:**
   ```bash
   # NixOS (Orca)
   orca --setup
   # Test all custom shortcuts
   
   # macOS (VoiceOver)
   # System Settings → Accessibility → VoiceOver → Commands
   ```

2. **Identify conflicting shortcuts**
   - Right Alt is commonly used by screen readers
   - Some navigation shortcuts may overlap

3. **Remap navigation layer to different key:**
   ```nix
   # Use Right Ctrl instead of Right Alt
   rightctrl = "layer(nav)";  # Change this
   ```

4. **Report conflicts:**
   - File issues on GitHub with your screen reader name
   - We'll document known conflicts and workarounds

### Issue: Documentation Readability

**Solution: High-Contrast Documentation**

Our documentation aims for WCAG 2.1 Level AA compliance:
- ✅ Markdown format (screen-reader friendly)
- ✅ Semantic headers
- ✅ Alt text for diagrams (where applicable)
- ✅ Code blocks properly marked up

**To improve readability:**
- Use browser reader mode
- Increase font size in terminal: `Ctrl+Plus`
- Use high-contrast terminal themes

---

## Hearing Impairments

**Good news:** Our keyboard configuration is entirely visual/tactile with no audio feedback requirements.

**Optional audio feedback:**
```bash
# NixOS: Add key press sounds (optional)
# Use xkbbell or similar for audio feedback if desired
```

---

## Age-Related Considerations

### Arthritis or Joint Stiffness

**Recommendations:**
1. Use larger keys (mechanical keyboards with lower actuation force)
2. Increase tap/hold timeout (300-500ms)
3. Enable sticky keys (toggle mode)
4. Consider split ergonomic keyboards (reduce ulnar deviation further)

### Slower Reaction Times

**Adjust timings:**
```nix
global = {
  overload_tap_timeout = 300;  # Increase to 300-400ms
};
```

---

## Temporary Disabilities

### Broken Arm/Hand

**Single-hand operation:**

1. **Enable sticky keys** (Solution 1 above)
2. **Use foot pedal** for modifiers
3. **Temporarily disable complex shortcuts:**
   ```nix
   # Comment out navigation layer temporarily
   # rightalt = "layer(nav)";
   ```

### Carpal Tunnel / Temporary RSI

**This configuration actually HELPS recovery:**
- More accessible modifiers reduce strain
- Navigation layer eliminates arrow key reaches
- Consider taking breaks every 25 minutes (Pomodoro technique)

---

## Alternative Input Methods

### Voice Control

**Compatible with voice coding:**

**NixOS:**
```bash
# Talon voice coding
# https://talonvoice.com/
# Our keyboard shortcuts don't interfere with voice commands
```

**macOS:**
```bash
# Native Voice Control or Dragon NaturallySpeaking
# System Settings → Accessibility → Voice Control
```

**Our navigation layer complements voice control:**
- Use voice for dictation
- Use Right Alt layer for precise cursor positioning

### Eye Tracking

**Compatible with eye trackers:**

**OptiKey (open source, Windows/Linux):**
```bash
# Our keyboard config works alongside eye tracking
# Use eye tracker for typing, keyboard for shortcuts
```

**Tobii Eye Tracker (macOS/Windows):**
- No conflicts with our configuration
- Eye tracker handles selection
- Physical keyboard handles commands

---

## Customization for Specific Conditions

### Parkinson's Disease

**Challenges:** Tremors, slower movements, difficulty with fine motor control

**Recommended adjustments:**
1. Increase tap timeout: 400-500ms
2. Enable sticky keys (oneshot mode)
3. Use larger, mechanical keyboard with light switches
4. Consider voice control as supplement

### Cerebral Palsy

**Challenges:** Involuntary movements, spasticity

**Recommended adjustments:**
1. Use toggle mode for modifiers
2. Increase tap timeout significantly (500-800ms)
3. Consider adaptive keyboards (larger keys, keyguards)
4. Use foot pedals or head switches for modifiers

### ADHD / Attention Disorders

**Challenges:** Difficulty remembering complex shortcuts

**Recommended adjustments:**
1. Start with minimal config (Caps→Super only)
2. Add one new shortcut per week
3. Use visual reminders (sticky notes, desktop widgets)
4. Practice with spaced repetition (Anki flashcards)

---

## Testing Your Accessible Configuration

### Validation Checklist

- [ ] Can activate all shortcuts without pain or strain
- [ ] Tap/hold threshold feels comfortable (no accidental triggers)
- [ ] Navigation works with assistive technology (screen readers, etc.)
- [ ] Can use configuration for 30+ minutes without discomfort
- [ ] Shortcuts don't conflict with assistive software
- [ ] Visual indicators (if needed) are visible and clear

### Feedback Form

**Help us improve accessibility:**

We're collecting feedback from users with disabilities to improve this configuration:

[Google Form Link - TBD]

**Share:**
- Your specific condition/disability
- What works well
- What needs improvement
- Custom modifications you've made

---

## Resources

### Organizations

- **ORCCA (Online Resource for Cognitive & Communication Accessibility):**  
  https://orcca.org/

- **Web Accessibility Initiative (WAI):**  
  https://www.w3.org/WAI/

- **AbilityNet (UK):**  
  https://abilitynet.org.uk/

### Assistive Technology

**Screen Readers:**
- Orca (Linux): https://help.gnome.org/users/orca/
- NVDA (Windows): https://www.nvaccess.org/
- JAWS (Windows): https://www.freedomscientific.com/
- VoiceOver (macOS): Built-in

**Voice Control:**
- Talon: https://talonvoice.com/
- Cursorless: https://www.cursorless.org/
- Dragon NaturallySpeaking: https://www.nuance.com/dragon.html

**Eye Tracking:**
- Tobii: https://www.tobii.com/
- OptiKey: https://github.com/OptiKey/OptiKey

### Medical Resources

**RSI Prevention:**
- RSI Action (UK): https://rsi-action.org.uk/
- NIOSH Ergonomics: https://www.cdc.gov/niosh/topics/ergonomics/

**Occupational Therapy:**
- AOTA: https://www.aota.org/
- BAOT (UK): https://www.rcot.co.uk/

---

## Contact & Support

**Questions about accessibility?**

- File an issue: https://github.com/[your-repo]/issues
- Tag with: `accessibility`, `a11y`
- We'll respond within 48 hours

**Need a custom configuration?**

We can help create specialized configs for specific disabilities. Reach out with details about your needs.

---

## Accessibility Statement

We are committed to making our keyboard configuration accessible to all users, regardless of ability. This includes:

- ✅ Providing alternatives for motor-limited users
- ✅ Reducing cognitive load for users with processing disorders
- ✅ Ensuring compatibility with screen readers and assistive technology
- ✅ Documenting accessibility considerations clearly
- ⚠️ Ongoing: Conducting user testing with disabled community members
- ⚠️ Ongoing: Gathering feedback and iterating on solutions

**This is a living document.** We update it based on community feedback and research.

**Last updated:** 2025-10-12  
**Next review:** 2026-01-12

---

**Everyone deserves an ergonomic, efficient keyboard setup. Let's make it accessible.** ♿️✨
