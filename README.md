# Simple Notepad

A clean, lightweight plain text editor for Linux — like Notepad, but for Linux.

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/simple-notepad)

---

## Features

- Open, save, and save-as any plain text file
- Print the current document
- Dark mode toggle (persisted between sessions)
- Adjustable font size (12–32px, persisted between sessions)
- Minimal UI built with the Yaru (Ubuntu/GNOME) design system

## Installation

### Snap Store

```bash
sudo snap install simple-notepad
```

### GitHub Releases

Pre-built binaries are available on the [Releases page](https://github.com/MelaineGerard/simple-notepad/releases) for both `x86_64` and `aarch64`:

| Format | Install |
|---|---|
| `.deb` | `sudo dpkg -i simple-notepad-<version>-amd64.deb` |
| `.rpm` | `sudo rpm -i simple-notepad-<version>-x86_64.rpm` |
| `AppImage` | `chmod +x simple-notepad-<version>-x86_64.AppImage && ./simple-notepad-<version>-x86_64.AppImage` |
| `.tar.gz` | Extract and run `bundle/simple_notepad` |

### Build from source

**Prerequisites**

- [Flutter SDK](https://docs.flutter.dev/get-started/install/linux) (stable channel, >=3.27.1)
- Linux build dependencies:

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

**Steps**

```bash
# Clone the repository
git clone https://github.com/melaine-gerard/simple-notepad.git
cd simple-notepad

# Install dependencies
flutter pub get

# Run in debug mode
flutter run -d linux

# Or build a release binary
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## Tech stack

| | |
|---|---|
| Language | Dart 3.x |
| Framework | Flutter |
| UI theme | [Yaru](https://pub.dev/packages/yaru) |
| File picker | [file_picker](https://pub.dev/packages/file_picker) |
| Persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| PDF / Print | [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) |
| Packaging | Snapcraft, `.deb`, `.rpm`, AppImage |

## Contributing

Pull requests are welcome. The project follows standard Flutter conventions — run `flutter analyze` before submitting.

## License

See [LICENSE](LICENSE).
