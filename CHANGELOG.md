# Changelog

## Unreleased

- Restore tabs, active document, cursor positions, encodings and recoverable drafts at startup; warn about missing files and allow disabling recovery (#25).
- Serialize recovery writes and flush before quit; explicitly discarded edits are excluded from the final session.

- Find / Replace panel with literal matching, navigation, match-case and replacement of one/all occurrences in the active tab (#13).
- Extension-based basic syntax highlighting with plain-text fallback and a persistent opt-out (#19).
- Complete common keyboard shortcut set, including Ctrl+F and Ctrl+H (#22).

- Independent document tabs with separate text, paths, encodings and undo histories (#16).
- Save / Discard / Cancel confirmation on tab close and window quit, including native window close requests (#18).
- UTF-8, UTF-16 LE/BE, ISO-8859-1 and ASCII input/output with strict conversion and BOM detection (#17).
- New tab/document, close-tab and quit shortcuts; dirty indicators in tabs and window title (#22).


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
