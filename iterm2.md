# iTerm2 Native Multiplexer Skill

Detected terminal: iTerm2.

Use AppleScript/System Events for native terminal control.

Supported actions:

- Split pane right: `osascript -e 'tell application "iTerm2" to tell current session of current window to split vertically with default profile'`
- Split pane down: `osascript -e 'tell application "iTerm2" to tell current session of current window to split horizontally with default profile'`
- New tab: `osascript -e 'tell application "System Events" to tell process "iTerm2" to keystroke "t" using command down'`
- New window: `osascript -e 'tell application "System Events" to tell process "iTerm2" to keystroke "n" using command down'`
- Rename tab: `osascript -e 'tell application "iTerm2" to set name of current tab of current window to "TITLE"'`

Unsupported or unclear actions:

- Rename pane/session from shell: no reliable one-shot command in this skill. Say unsupported.
- Resize/focus/zoom pane from shell: say unsupported unless an exact iTerm2 AppleScript command is known.

Do not suggest tmux for iTerm2-native panes.
