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
