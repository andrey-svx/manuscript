# 📜 Manuscript

**Manuscript** is a lightweight, zero-dependency Swift CLI tool for **black-box UI testing** of iOS Apps running in the Simulator. 

It inspects the screen using the macOS Accessibility API, finds UI elements (TextFields) based on a flexible YAML configuration, and fills them with data.

> 🚀 **Why Manuscript?**
> Unlike XCUITest or Appium, Manuscript runs *externally* from your Mac terminal. It doesn't require injecting code into your app, rebuilding your project, or launching a heavy test runner. It just looks at the Simulator window and interacts with it like a user would.

---

## ✨ Features

- **🔎 Smart Universal Search**: Finds elements using a cascading strategy:
  1. **Accessibility ID** (Best for testability)
  2. **Label Anchor** (Finds input next to a specific text label)
  3. **Placeholder Text** (Matches placeholder value)
  4. **Value Match** (Finds fields already filled with specific text)
- **🧠 Intelligent Simulator Selection**: Automatically detects and connects to the active Simulator window (z-order based). Supports multiple booted devices.
- **⚡️ Zero Dependencies**: Single-file Swift script. No `npm`, `gem`, `pip`, or compiled binary requirements.
- **📱 Framework Agnostic**: Works perfectly with both **UIKit** (even complex nested hierarchies) and **SwiftUI**.
- **♻️ Reentrant**: Can be run multiple times safely. If a field is already filled, it detects it and skips.

---

## 📦 Installation

Since Manuscript is a standalone script, installation is as simple as downloading it.

```bash
# Make the script executable
chmod +x manuscript.swift
```

---

## 🚀 Usage

Run the script providing a path to your configuration file:

```bash
./manuscript.swift --screen my_screen_config.yaml
```

**Note**: On first run, macOS will ask for **Accessibility Permissions** for your terminal app (e.g., Terminal, iTerm, VSCode). This is required to inspect the Simulator window.

---

## 🛠 Configuration

Manuscript uses simple YAML files to define what to look for and what to type.

### Example `login.yaml`

```yaml
title: "Login Screen Test"

fields:
  # Strategy 1: Best Practice (Explicit ID)
  - id: "username_field"
    value: "test_user"

  # Strategy 2: Search by Label (Great for 3rd party UI)
  # Finds static text "Password" and types in the next field found
  - label: "Password"
    value: "secret123"

  # Strategy 3: Search by Placeholder
  - placeholder: "Email Address"
    value: "john@example.com"

  # Strategy 4: Visual Search (Just finds a field with this value)
  - value: "Pre-filled text"
```

### Field Options

| Key | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | `String` | No | The `accessibilityIdentifier` of the element (or its container). |
| `label` | `String` | No | Text of a static label physically located before/near the target field. |
| `placeholder` | `String` | No | The placeholder text inside the empty field. |
| `value` | `String` | **Yes** | The text to type into the field. Also used for "Value Match" strategy. |

---

## ⚙️ How It Works

Manuscript connects to the `Simulator.app` process via the macOS Accessibility API (`AXUIElement`).

1. **Discovery**: It scans active windows to find the one belonging to the currently active Simulator device.
2. **Analysis**: It parses the YAML config and iterates through requested fields.
3. **Execution**: For each field, it attempts to find a match using the **Universal Search Strategy**:
   - **Step 1**: Does an element with this `id` exist? (Handles nested groups automatically).
   - **Step 2**: If no ID, is there a Label with text `label`? If yes, find the nearest TextField.
   - **Step 3**: Is there a TextField with `placeholder` value?
   - **Step 4**: Is there a TextField that already contains `value`?
4. **Action**: Once found, it injects the text value directly.

---

## 📝 License

MIT License. Feel free to use and modify.
