# Kitty Native Multiplexer Skill

Detected terminal: Kitty.

Use Kitty remote control through `kitten @`. This requires remote control to be enabled and `KITTY_WINDOW_ID` to be present.

Supported actions:

- Split pane right: `kitten @ launch --type=window --location=vsplit --cwd=current`
- Split pane down: `kitten @ launch --type=window --location=split --cwd=current`
- New tab: `kitten @ launch --type=tab --cwd=current`
- New OS window: `kitten @ launch --type=os-window --cwd=current`
- Rename tab: `kitten @ set-tab-title "TITLE"`
- Rename pane/window: `kitten @ set-window-title "TITLE"`
- Resize pane horizontally: `kitten @ resize-window --axis=horizontal --increment=5`
- Resize pane vertically: `kitten @ resize-window --axis=vertical --increment=5`
- Close pane/window: `kitten @ close-window`
- Close tab: `kitten @ close-tab`

Unsupported or unclear actions:

- If `kitten @` fails because remote control is disabled, say Kitty remote control is not enabled.

Do not suggest tmux for Kitty-native panes.
