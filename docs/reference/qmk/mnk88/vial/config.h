#pragma once

// VIAL Configuration
#define VIAL_KEYBOARD_UID {0x8F, 0x7D, 0x6C, 0x5B, 0x4A, 0x39, 0x28, 0x17}

// Vial unlock combo - ESC + Enter (row 0 col 0, row 3 col 13)
#define VIAL_UNLOCK_COMBO_ROWS { 0, 3 }
#define VIAL_UNLOCK_COMBO_COLS { 0, 13 }

// Tapping configuration
#define TAPPING_TERM 200
#define TAPPING_TOGGLE 2

// Reduce firmware size for VIAL
#define NO_ACTION_ONESHOT
#define NO_ACTION_FUNCTION

// Debounce (matching official config)
#define DEBOUNCE 5


