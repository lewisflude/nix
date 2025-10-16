# Core VIAL/VIA configuration
VIAL_ENABLE = yes
VIA_ENABLE = yes        # VIAL requires VIA to be enabled
LTO_ENABLE = yes        # Re-enable LTO for size optimization

# VIAL-specific settings
QMK_SETTINGS = no       # Disable QMK settings to avoid VIAL conflicts
VIALRGB_ENABLE = no     # Disable VIAL RGB features
VIAL_INSECURE = no      # Keep security enabled (use unlock combo)

# Build Options (matching official MNK88 config)
BOOTMAGIC_ENABLE = yes  # Enable Bootmagic Lite
MOUSEKEY_ENABLE = yes   # Mouse keys
EXTRAKEY_ENABLE = yes   # Audio control and System control
CONSOLE_ENABLE = yes    # Console for debug (needed for communication)
COMMAND_ENABLE = yes    # Commands for debug and configuration
NKRO_ENABLE = yes       # Enable N-Key Rollover
BACKLIGHT_ENABLE = no   # No backlight
RGBLIGHT_ENABLE = no    # No RGB underglow for this build
AUDIO_ENABLE = no       # No audio output
ENCODER_ENABLE = no     # No encoder support

# Disable unused features to save space
COMBO_ENABLE = no
KEY_OVERRIDE_ENABLE = no
TAP_DANCE_ENABLE = no
AUTO_SHIFT_ENABLE = no
SPACE_CADET_ENABLE = no
GRAVE_ESC_ENABLE = no
MAGIC_ENABLE = no

# OS target for palette combo selection
# OPT_DEFS += -DOS_LINUX

