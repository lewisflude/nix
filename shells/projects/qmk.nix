{ pkgs, ... }:
pkgs.mkShell {
  buildInputs = [
    pkgs.qmk
    pkgs.gcc-arm-embedded
    pkgs.dfu-util
    pkgs.avrdude
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.setuptools
  ];

  shellHook = ''
    echo "🛠️  QMK development shell ready (MNK88 / STM32F072)"
    echo "• qmk version: $(qmk --version 2>/dev/null || echo not-installed)"
    echo "• dfu-util: $(dfu-util --version | head -n1)"
    echo "• arm-none-eabi-gcc: $(arm-none-eabi-gcc --version | head -n1)"

    alias qmk-setup='qmk setup -H ./qmk_firmware || true'
    alias qmk-compile-mnk88='qmk compile -kb kopibeng/mnk88 -km default'
    alias qmk-flash-mnk88='qmk flash -kb kopibeng/mnk88 -km default'
  '';
}
