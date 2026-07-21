{
  lib,
  stdenv,
  signalLib,
  mode ? "dark",
}:

let
  inherit (lib) removePrefix;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode mode;
  colors = signalLib.getColors themeMode;

  # Helper to remove # from hex colors
  hexRaw = color: removePrefix "#" color.hex;

  # Extract colors for SDDM theme
  surface-base = colors.tonal."surface-base";
  surface-raised = colors.tonal."surface-hover";
  text-primary = colors.tonal."text-primary";
  text-secondary = colors.tonal."text-secondary";
  text-tertiary = colors.tonal."text-tertiary";
  accent-focus = colors.accent.secondary.Lc75;
  accent-danger = colors.accent.danger.Lc75;
  divider = colors.tonal."divider-primary";

  # Theme metadata
  metadataDesktop = ''
    [SddmGreeterTheme]
    Name=Signal ${lib.strings.toUpper (lib.substring 0 1 themeMode)}${lib.substring 1 (-1) themeMode}
    Description=Signal Design System theme for SDDM (${themeMode} mode)
    Author=Signal Design System
    Copyright=(c) 2024-2026
    License=MIT
    Type=sddm-theme
    Version=1.0
    Website=https://github.com/lewisflude/signal-nix
    MainScript=Main.qml
    ConfigFile=theme.conf
    TranslationsDirectory=
    Theme-Id=signal-${themeMode}
    Theme-API=2.0
  '';

  # Theme configuration
  themeConf = ''
    [General]
    Background=${hexRaw surface-base}
    Foreground=${hexRaw text-primary}

    # UI Colors
    AccentColor=${hexRaw accent-focus}
    SecondaryText=${hexRaw text-secondary}
    TertiaryText=${hexRaw text-tertiary}
    InputBackground=${hexRaw surface-raised}
    InputBorder=${hexRaw divider}
    ErrorColor=${hexRaw accent-danger}
  '';

  # Main QML file
  mainQml = ''
    import QtQuick 2.15
    import QtQuick.Layouts 1.15
    import QtQuick.Controls 2.15
    import SddmComponents 2.0

    Rectangle {
        id: root
        width: 1920
        height: 1080

        // Background
        color: "#${hexRaw surface-base}"

        // Main content
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 32

            // Logo / Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Signal"
                font.pixelSize: 48
                font.bold: true
                color: "#${hexRaw text-primary}"
            }

            // Login container
            Rectangle {
                Layout.preferredWidth: 400
                Layout.preferredHeight: 300
                color: "#${hexRaw surface-raised}"
                radius: 8
                border.color: "#${hexRaw divider}"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 16

                    // User selection
                    ComboBox {
                        id: userSelect
                        Layout.fillWidth: true
                        model: userModel
                        textRole: "name"
                        currentIndex: userModel.lastIndex

                        background: Rectangle {
                            color: "#${hexRaw surface-base}"
                            border.color: "#${hexRaw divider}"
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: userSelect.displayText
                            color: "#${hexRaw text-primary}"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    // Password field
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "Password"
                        echoMode: TextInput.Password
                        focus: true

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                login()
                            }
                        }

                        background: Rectangle {
                            color: "#${hexRaw surface-base}"
                            border.color: passwordField.activeFocus ? "#${hexRaw accent-focus}" : "#${hexRaw divider}"
                            border.width: passwordField.activeFocus ? 2 : 1
                            radius: 4
                        }

                        color: "#${hexRaw text-primary}"
                    }

                    // Session selection
                    ComboBox {
                        id: sessionSelect
                        Layout.fillWidth: true
                        model: sessionModel
                        textRole: "name"
                        currentIndex: sessionModel.lastIndex

                        background: Rectangle {
                            color: "#${hexRaw surface-base}"
                            border.color: "#${hexRaw divider}"
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: sessionSelect.displayText
                            color: "#${hexRaw text-secondary}"
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    // Login button
                    Button {
                        Layout.fillWidth: true
                        text: "Login"
                        onClicked: login()

                        background: Rectangle {
                            color: parent.pressed ? Qt.darker("#${hexRaw accent-focus}", 1.2) : "#${hexRaw accent-focus}"
                            radius: 4
                            border.width: 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#${hexRaw surface-base}"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }
                }
            }

            // Status message
            Text {
                id: statusMessage
                Layout.alignment: Qt.AlignHCenter
                text: ""
                color: "#${hexRaw accent-danger}"
                visible: text !== ""
                font.pixelSize: 12
            }
        }

        // Power controls (bottom right)
        RowLayout {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 32
            spacing: 16

            Button {
                text: "Reboot"
                onClicked: sddm.reboot()
                background: Rectangle {
                    color: "transparent"
                    border.color: "#${hexRaw divider}"
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "#${hexRaw text-secondary}"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Button {
                text: "Shutdown"
                onClicked: sddm.powerOff()
                background: Rectangle {
                    color: "transparent"
                    border.color: "#${hexRaw divider}"
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "#${hexRaw text-secondary}"
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Functions
        function login() {
            statusMessage.text = ""
            sddm.login(userSelect.currentText, passwordField.text, sessionSelect.currentIndex)
        }

        Component.onCompleted: {
            // Focus password field if user is already selected
            if (userSelect.currentIndex >= 0) {
                passwordField.forceActiveFocus()
            }
        }

        Connections {
            target: sddm
            function onLoginFailed() {
                statusMessage.text = "Login failed. Please try again."
                passwordField.text = ""
                passwordField.forceActiveFocus()
            }
        }
    }
  '';
in
stdenv.mkDerivation {
  name = "signal-sddm-theme-${themeMode}";
  version = "1.0.0";

  src = ./.;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/share/sddm/themes/signal-${themeMode}

    # Install Main.qml
    cat > $out/share/sddm/themes/signal-${themeMode}/Main.qml << 'EOF'
    ${mainQml}
    EOF

    # Install metadata.desktop
    cat > $out/share/sddm/themes/signal-${themeMode}/metadata.desktop << 'EOF'
    ${metadataDesktop}
    EOF

    # Install theme.conf
    cat > $out/share/sddm/themes/signal-${themeMode}/theme.conf << 'EOF'
    ${themeConf}
    EOF

    # Create preview image placeholder
    echo "Preview image placeholder" > $out/share/sddm/themes/signal-${themeMode}/preview.png
  '';

  meta = {
    description = "Signal Design System theme for SDDM (${themeMode} mode)";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
