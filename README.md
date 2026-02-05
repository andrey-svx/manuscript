# 📜 Manuscript

![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13+-blue.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

**Stop typing test data manually.** Manuscript auto-fills forms on your iOS Simulator using simple YAML configs.

No test frameworks. No code injection. No rebuilding. Just run a command and watch the magic.

<p align="center">
  <img src="assets/demo.gif" alt="Manuscript automatically fills a form in iOS Simulator" width="800">
</p>

## Quick Start (60 seconds)

### 1. Install

```bash
git clone https://github.com/andrey-svx/manuscript.git
cd manuscript
git checkout 1.0.0
sudo make install
```

### 2. Create a simple config

```yaml
# login.yaml
name: "Login Form"
steps:
  - target: "email_field"
    value: "dev@example.com"
  - target: "Password"
    value: "secret123"
```

### 3. Run

```bash
manuscript run login.yaml --current
```

✅ Done! Your simulator form is filled.


## Two Usage Patterns

### Pattern A: Quick & Dirty (Files Anywhere)

Perfect for instant testing. Keep YAML files wherever you want:

```bash
# Run from any location
manuscript run ~/Desktop/checkout.yaml --current
manuscript run ./test-data/profile.yaml --current
```

### Pattern B: Team Integration (Project Folder)

Initialize Manuscript in your project root:

```bash
cd YourProject
manuscript init
```

This creates `.manuscript/` folder with example config. Now your team runs:

```bash
manuscript run login.yaml           # Uses .manuscript/login.yaml
manuscript list                     # Shows all available configs
```

> 📚 **Want more?** Manuscript supports config management, templates, and team workflows.  
> Run `manuscript --help` to explore all commands.


## Configuration

Manuscript finds fields using **4 smart strategies** (in order):

| Strategy | Target Value | Example |
|----------|--------------|---------|
| **1. Accessibility ID** | `accessibilityIdentifier` | `"email_field"` |
| **2. Label Anchor** | Text label near field | `"Password"` |
| **3. Placeholder** | Placeholder text | `"Enter amount"` |
| **4. Current Value** | Pre-filled content | `"Invoice Payment"` |

```yaml
name: "Bank Transfer"
steps:
  - target: "transfer_recipient"      # Found by ID
    value: "John Doe"
    
  - target: "Beneficiary IBAN"        # Found by label
    value: "DE89370400440532013000"
    
  - target: "0.00"                    # Found by placeholder
    value: "420.00"
```


## Limitations

| Constraint | Details |
|------------|---------|
| **macOS only** | Uses macOS Accessibility API |
| **iOS Simulator only** | Cannot run on real devices |
| **Text fields only** | Works with TextField/TextArea, not buttons or pickers |
| **App must be running** | Simulator with your app must be booted and visible |
| **Accessibility permission** | Terminal needs Accessibility access in System Settings |


## First Run: Grant Permissions

On first run, macOS will ask for Accessibility permissions:

**System Settings → Privacy & Security → Accessibility → Enable your terminal**


## Learn More

```bash
manuscript --help          # All commands
manuscript run --help      # Run options
manuscript init --help     # Project setup
```

**Article:** [Fill iOS Simulator Forms in 60 Seconds](https://medium.com/@andron.isaev/fill-ios-simulator-forms-in-60-seconds-a-cli-tool-with-zero-dependencies-f4154e466806) — why I built this tool


## Feedback

Found a bug or have a feature request?  
→ [Open an Issue](https://github.com/andrey-svx/manuscript/issues)


## Contributing

Pull requests are welcome! For major changes, please open an issue first.


## License

MIT © 2026 andrey-svx
