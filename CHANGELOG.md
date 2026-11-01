# Changelog

## 0.3.0 — 2026-11-01

### Added
- Independent document tabs, each with its own text, file path, selection, encoding and undo/redo history (#16, #52).
- Save / Discard / Cancel confirmation before closing a tab or quitting, including native window-close requests; unsaved changes are marked in tabs and the title (#18, #52).
- UTF-8 (with or without BOM), UTF-16 LE/BE, ISO-8859-1 and ASCII input/output. File opening detects BOMs; legacy files can be opened with an explicit encoding (#17, #52).
- Find / Replace with literal matching, optional case sensitivity, occurrence highlighting, wrapped previous/next navigation and replacement of one or all occurrences in the active tab (#13, #54).
- Basic syntax highlighting for Python, JavaScript/TypeScript, JSON, YAML, Markdown and Dart, with a persistent opt-out and plain-text fallback for unknown or large documents (#19, #54).
- Restore tabs, the active document, cursor selections, encodings and recoverable unsaved drafts on startup. Missing files produce warnings; recovery can be disabled in Settings (#25, #55).
- Distraction-free focus mode with F11 or Ctrl+Shift+F, Escape and a mouse-accessible exit button (#23, #51).
- Undo/redo menu controls and the complete common keyboard shortcut set, including Ctrl+N/T/O/S/Shift+S/F/H/W/Q, Ctrl+Z/Y/Shift+Z and Ctrl+P (#15, #22, #51, #54).

### Reliability and data protection
- Existing files are saved through a flushed temporary file and atomic replacement, preserving Linux permission bits and following symlinks.
- Cancelled file pickers, failed writes, unsupported encoding conversion and edits made during a save retain unsaved documents.
- Quit approval is revalidated across all tabs before the window is destroyed.
- Explicitly discarded drafts are omitted from the final recovery session. Unrestorable snapshots are backed up separately; failed backups pause replacement rather than erase recovery data.
- Search navigation reveals offscreen matches without taking search focus. IME composition preserves Flutter's standard text rendering.
- Syntax scanning is bounded and avoids repeatedly scanning unterminated comments.
- Focus-mode and font changes retain document text, selection and undo history.

### Build and packaging
- Linux x86_64 and ARM64 packages: AppImage, deb, rpm and tar.gz.
- Correct package launchers to execute the actual `simple-notepad` binary.
- Validate the bundle executable and perform a headless native startup smoke test before packaging and publication.
- `window_manager ^0.5.1` is now a direct dependency for native close interception.
- Release artifact actions updated to `actions/upload-artifact v7` and `actions/download-artifact v8`.
- Flutter application version `0.3.0+2`; About and Snap version `0.3.0`.
- Build requirements reflect the existing dependency floor: Flutter 3.47+ / Dart 3.13+.

### Validation
Analysis, unit/widget tests and Linux builds run for both architectures. Coverage includes tab isolation, save failures and cancellation, atomic writes, encoding round-trips, search/replacement, IME rendering, recovery ordering, invalid session backups and quit/discard behavior.

**Full changelog:** https://github.com/MelaineGerard/simple-notepad/compare/0.2.0...0.3.0


## 0.2.0 — 2026-11-01

### Added
- Live line, word and character counters in the editor status bar, including correct handling of Unicode grapheme clusters and mixed line endings (#14, #45).
- System proportional or monospace editor fonts, applied immediately and remembered between sessions (#21, #45).
- Unit and widget tests for document counters, live font selection, preference persistence and narrow windows; tests now run in CI on Linux x64 and ARM64 (#45).

### Fixed
- Migrated file opening to the single-file API in `file_picker 13`.
- Migrated “Save as” to the byte-based API and converted the returned file URI to a local path.
- Pinned `archive 4.4.0` to supply the decoder API required by the image dependency and restore Linux compilation (#39, #41).
- Removed an unmanaged editor theme listener and disposed the editor text controller correctly (#45).
- Settings controls refresh immediately; the status bar wraps in narrow windows (#45).
- Aligned Flutter, About dialog and Snap package versions to `0.2.0`.

### Dependency updates
All dependency updates merged since 0.1.5 are included, including the later updates in #46, #47 and #48:
- `file_picker`: 10.3.10 → 11.0.2 → 13.3.0 (constraint `^13.0.0`), #41 and #39.
- `yaru`: 10.0.0 → 10.1.0 → 11.0.0, #43 and #39.
- `pdf`: 3.11.3 → 3.12.0 → 3.13.1, #36 and #46.
- `printing`: 5.14.2 → 5.14.3 → 5.15.1, #37 and #47.
- `shared_preferences`: 2.5.4 → 2.5.5 → 2.5.6, #38 and #48.
- Updated transitive dependencies for the federated file-picker and Yaru packages.

### Build and release
- `actions/checkout`: v6 → v7 (#44).
- `softprops/action-gh-release`: v2 → v3 (#42).
- Publish Linux packages for x86_64 and ARM64: tar.gz, AppImage, deb and rpm.
- Release branches now validate the code, build packages and publish the versioned GitHub release with these notes.

**Full changelog:** https://github.com/MelaineGerard/simple-notepad/compare/0.1.5...0.2.0
