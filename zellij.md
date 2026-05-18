# zellij Multiplexer Skill

Detected environment: attached zellij session.

Use zellij commands only when `$ZELLIJ` is set.

Supported actions:

- Split/new pane right: `zellij action new-pane --direction right`
- Split/new pane down: `zellij action new-pane --direction down`
- Resize pane: `zellij action resize left|right|up|down`
- Focus pane: `zellij action move-focus left|right|up|down`
- Close pane: `zellij action close-pane`
- Close tab: `zellij action close-tab`
- New tab: `zellij action new-tab`

Unsupported or unclear actions:

- Rename pane/tab: say unsupported unless current `zellij action --help` exposes a rename command.
