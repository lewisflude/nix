# Nix Configuration Documentation

A modern, cross-platform Nix setup for both macOS (nix-darwin) and Linux (NixOS), with shared Home Manager and development environments.

## 📚 Documentation Index

### **🚀 Getting Started**
- [**Quick Start Guide**](guides/quick-start.md) - Get up and running fast
- [**Installation Guide**](guides/installation.md) - Detailed setup instructions
- [**Configuration Guide**](guides/configuration.md) - Customizing your setup

### **📖 User Guides**
- [**Development Environments**](guides/development.md) - Using development shells and environments
- [**Secrets Management**](guides/secrets.md) - Managing secrets with SOPS
- [**System Management**](guides/system-management.md) - Building, updating, and maintaining your system
- [**Cross-Platform Usage**](guides/cross-platform.md) - macOS vs Linux differences
- [**Zellij Workflow**](guides/zellij-workflow.md) - Terminal multiplexer usage and patterns

### **🎹 Keyboard Configuration (NEW v2.0 - Cross-Platform Ergonomic Hybrid)**

**Quick Start:**
- [**⭐ Keyboard Quick Start**](guides/keyboard-quickstart.md) - **START HERE!** 5-minute setup (both platforms)
- [**📋 Cheat Sheet**](guides/keyboard-cheatsheet.md) - **Print this!** Quick reference card

**Platform-Specific:**
- [**🍎 macOS Guide**](guides/keyboard-macos.md) - **NEW!** Complete macOS setup with Karabiner
- [**🌍 Cross-Platform Guide**](guides/keyboard-cross-platform.md) - **NEW!** NixOS vs macOS comparison
- [**🪟 Niri Keybinds**](guides/keyboard-niri.md) - Window manager details (NixOS)

**Complete Documentation:**
- [**📚 Keyboard Reference**](guides/keyboard-reference.md) - Complete shortcut reference
- [**📖 Master README**](guides/KEYBOARD-README.md) - Complete documentation index
- [**🔄 Migration Guide**](guides/keyboard-migration.md) - Transition from old setup
- [**📈 Learning Curve**](guides/keyboard-learning-curve.md) - Skill acquisition timeline
- [**♿ Accessibility Guide**](guides/keyboard-accessibility.md) - Alternative configurations
- [**🚀 Deployment Guide**](KEYBOARD-DEPLOYMENT.md) - Production deployment instructions

**Technical:**
- [**🔧 Firmware Update**](guides/keyboard-firmware-update.md) - Update your keyboard (works on both!)
- [**📊 Firmware Status**](reference/mnk88-firmware-status.md) - Firmware verification & changelog
- [**📋 Update Summary**](KEYBOARD-UPDATE-SUMMARY.md) - What changed in v2.0

**Legacy Documentation:**
- [**📜 Legacy: Setup**](guides/keyboard-setup.md) - Original F13-only configuration
- [**📜 Legacy: Usage**](guides/keyboard-usage.md) - Original usage patterns
- [**📜 Legacy: Winkeyless**](guides/keyboard-winkeyless-true.md) - Original WKL guide

### **📋 Reference**
- [**Directory Structure**](reference/directory-structure.md) - Complete project layout
- [**Module Reference**](reference/modules.md) - All available modules and their purpose
- [**CLI Commands**](reference/commands.md) - Common command reference
- [**Configuration Options**](reference/config-options.md) - Available configuration settings
- [**Zellij Configuration**](reference/zellij-config.md) - Zellij technical reference
- [**MNK88 Keyboard Layout**](reference/mnk88-universal.json) - Universal VIA/VIAL layout

### **🔧 Advanced Topics**
- [**Architecture Overview**](reference/architecture.md) - System design and patterns
- [**Adding New Modules**](guides/adding-modules.md) - Creating new system/home modules
- [**Platform Integration**](reference/platform-integration.md) - Cross-platform patterns
- [**Troubleshooting**](guides/troubleshooting.md) - Common issues and solutions

### **🤖 AI Assistant Documentation**
- [**AI Assistant Guide**](ai-assistants/README.md) - Unified guide for Claude, ChatGPT, Cursor
- [**Project Context**](ai-assistants/project-context.md) - Architecture and patterns for AI assistants
- [**Common Tasks**](ai-assistants/common-tasks.md) - Frequent development tasks and patterns

---

## 🎯 Quick Navigation

| I want to... | Go to... |
|---------------|----------|
| **Get started quickly** | [Quick Start Guide](guides/quick-start.md) |
| **Add a new package** | [Configuration Guide](guides/configuration.md#adding-packages) |
| **Set up a dev environment** | [Development Environments](guides/development.md) |
| **Fix a build issue** | [Troubleshooting](guides/troubleshooting.md) |
| **Understand the architecture** | [Architecture Overview](reference/architecture.md) |
| **Add a new host** | [Configuration Guide](guides/configuration.md#adding-hosts) |
| **Work with secrets** | [Secrets Management](guides/secrets.md) |
|| **Use terminal multiplexing** | [Zellij Workflow](guides/zellij-workflow.md) |
| **Setup my keyboard** | [Keyboard Setup](guides/keyboard-setup.md) |

---

## 📄 Legacy Files

The following files in the repository root are maintained for compatibility but may be moved in the future:

- `README.md` - Main repository README (now points here)
- `CLAUDE.md`, `CODEX.md`, `CURSOR.md` - Now consolidated in [`ai-assistants/`](ai-assistants/)

---

**📍 You are here:** `docs/README.md` - Documentation hub and navigation
