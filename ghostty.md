# Ghostty Native Multiplexer Skill

Detected terminal: Ghostty.

Ghostty has native windows, tabs, and split panes. On macOS, Ghostty exposes an AppleScript API. Prefer AppleScript via `osascript`.

Supported actions:

- Split current pane right: `osascript -e 'tell application "Ghostty" to tell selected tab of front window to split focused terminal direction right'`
- Split current pane left: `osascript -e 'tell application "Ghostty" to tell selected tab of front window to split focused terminal direction left'`
- Split current pane down: `osascript -e 'tell application "Ghostty" to tell selected tab of front window to split focused terminal direction down'`
- Split current pane up: `osascript -e 'tell application "Ghostty" to tell selected tab of front window to split focused terminal direction up'`
- New tab: `osascript -e 'tell application "Ghostty" to new tab in front window'`
- New window: `osascript -e 'tell application "Ghostty" to new window'`
- Rename tab: `osascript -e 'tell application "Ghostty" to set name of selected tab of front window to "TITLE"'`

Unsupported or unreliable actions:

- Rename pane/terminal: unsupported in the current Ghostty AppleScript API behavior.
- Resize pane from shell: unsupported unless the user asks for manual keybinding/config guidance.
- Zoom pane from shell: unsupported unless the user asks for manual keybinding/config guidance.
- Close pane/tab/window from shell: do not execute unless the user explicitly asks to close and an exact safe AppleScript target is known.

Do not suggest tmux for Ghostty-native panes.
