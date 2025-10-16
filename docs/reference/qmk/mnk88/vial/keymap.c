#include QMK_KEYBOARD_H

enum custom_layers {
  _BASE,
  _L1,
  _L2,
};

// Cross-platform palette combo for VSCode/commands
#ifdef OS_LINUX
#  define PALETTE_MACRO SS_LCTL(SS_LSFT("p"))
#else
#  define PALETTE_MACRO SS_LGUI(SS_LSFT("p"))
#endif

// Custom keycodes for macros
enum custom_keycodes {
  MC_FOCUS_TERM = SAFE_RANGE,  // F13: Focus Terminal
  MC_FOCUS_BROWSER,             // Print Screen: Focus Browser
  MC_GIT_PUSH,                  // Scroll Lock: Git Push
  MC_RELOAD_WIN,                // Pause/Break: Reload Window
  MC_GIT_PULL,                  // Layer 1, P: Git Pull
  MC_GIT_STASH,                 // Layer 1, S: Git Stash
  MC_GIT_COMMIT,                // Layer 1, C: Git Commit
  MC_TILE_LEFT,                 // Layer 2, Left Arrow: Tile Left
  MC_TILE_RIGHT,                // Layer 2, Right Arrow: Tile Right
  MC_MAXIMIZE,                  // Layer 2, Up Arrow: Maximize
  MC_MINIMIZE,                  // Layer 2, Down Arrow: Minimize/Center
  MC_KVM_1,                     // Layer 2, 1: KVM Device 1
  MC_KVM_2,                     // Layer 2, 2: KVM Device 2
  MC_KVM_3,                     // Layer 2, 3: KVM Device 3
};

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
  if (!record->event.pressed) return true;
  switch (keycode) {
    case MC_FOCUS_TERM:
      // F13 will be handled by OS (Karabiner/Hammerspoon/WM) to focus terminal
      SEND_STRING(SS_TAP(X_F13));
      return false;
    case MC_FOCUS_BROWSER:
      // Print Screen will be handled by OS to focus browser
      SEND_STRING(SS_TAP(X_PSCR));
      return false;
    case MC_GIT_PUSH:
      SEND_STRING(PALETTE_MACRO "Git: Push" SS_TAP(X_ENTER));
      return false;
    case MC_RELOAD_WIN:
      SEND_STRING(PALETTE_MACRO "Developer: Reload Window" SS_TAP(X_ENTER));
      return false;
    case MC_GIT_PULL:
      SEND_STRING(PALETTE_MACRO "Git: Pull" SS_TAP(X_ENTER));
      return false;
    case MC_GIT_STASH:
      SEND_STRING(PALETTE_MACRO "Git: Stash" SS_TAP(X_ENTER));
      return false;
    case MC_GIT_COMMIT:
      SEND_STRING(PALETTE_MACRO "Git: Commit" SS_TAP(X_ENTER));
      return false;
    case MC_TILE_LEFT:
      SEND_STRING(SS_DOWN(X_LGUI) SS_DOWN(X_LALT) SS_TAP(X_LEFT) SS_UP(X_LALT) SS_UP(X_LGUI));
      return false;
    case MC_TILE_RIGHT:
      SEND_STRING(SS_DOWN(X_LGUI) SS_DOWN(X_LALT) SS_TAP(X_RIGHT) SS_UP(X_LALT) SS_UP(X_LGUI));
      return false;
    case MC_MAXIMIZE:
      SEND_STRING(SS_DOWN(X_LGUI) SS_DOWN(X_LALT) SS_TAP(X_F) SS_UP(X_LALT) SS_UP(X_LGUI));
      return false;
    case MC_MINIMIZE:
      SEND_STRING(SS_DOWN(X_LGUI) SS_DOWN(X_LALT) SS_TAP(X_C) SS_UP(X_LALT) SS_UP(X_LGUI));
      return false;
    case MC_KVM_1:
      SEND_STRING(SS_TAP(X_SCRL) SS_TAP(X_SCRL) SS_TAP(X_1));
      return false;
    case MC_KVM_2:
      SEND_STRING(SS_TAP(X_SCRL) SS_TAP(X_SCRL) SS_TAP(X_2));
      return false;
    case MC_KVM_3:
      SEND_STRING(SS_TAP(X_SCRL) SS_TAP(X_SCRL) SS_TAP(X_3));
      return false;
  }
  return true;
}

// Use MT/LT per spec from keyboard-keymap.md

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

  // Base Layer (Layer 0) - WKL F13 TKL layout per keyboard-keymap.md
  [_BASE] = LAYOUT_all(
    KC_ESC,  KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,  KC_F11,  KC_F12,  MC_FOCUS_TERM,    MC_FOCUS_BROWSER, MC_GIT_PUSH, MC_RELOAD_WIN,
    KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,    KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS, KC_EQL,  KC_BSPC, KC_BSPC, KC_INS,  KC_HOME, KC_PGUP,
    KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_LBRC, KC_RBRC, KC_BSLS,          KC_DEL,  KC_END,  KC_PGDN,
    KC_LCTL, KC_A,    KC_S,    KC_D,    KC_F,    KC_G,    KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,          KC_ENT,
    KC_LSFT, KC_NUBS, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_RSFT, KC_TRNS,                   KC_UP,
    LT(_L2, KC_LCTL), KC_TRNS, KC_LALT,                            LT(_L1, KC_SPC),                            KC_RALT, KC_TRNS, KC_TRNS, KC_RCTL,          KC_LEFT, KC_DOWN, KC_RGHT
  ),

  // Layer 1 (Hold Spacebar) - Productivity Layer
  [_L1] = LAYOUT_all(
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,          _______, _______, _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
    _______, _______, _______, _______, _______, _______, KC_HOME, KC_PGDN, KC_PGUP, KC_END,  MC_GIT_PULL, _______, _______, _______,          _______, _______, _______,
    _______, _______, MC_GIT_STASH, _______, _______, _______, KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT, _______, _______,          _______,
    _______, _______, _______, _______, MC_GIT_COMMIT, _______, _______, _______, _______, _______, _______, _______, _______, _______,             _______,
    _______, _______, _______,                            _______,                            _______, _______, _______, _______,          _______, _______, _______
  ),

  // Layer 2 (Hold Left Ctrl) - System Layer with KVM & Window Management
  [_L2] = LAYOUT_all(
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,          _______, _______, _______,
    _______, MC_KVM_1, MC_KVM_2, MC_KVM_3, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,          _______, _______, _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,          _______,
    _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,             MC_MAXIMIZE,
    _______, _______, _______,                            _______,                            _______, _______, _______, _______,          MC_TILE_LEFT, MC_MINIMIZE, MC_TILE_RIGHT
  ),
};


