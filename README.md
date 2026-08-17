# Omarchy Workspace Names

A native Omarchy 4 / Quickshell plugin for people who have outgrown anonymous
workspace numbers.

- Name the current workspace with **Super+Ctrl+Shift+W**.
- Fuzzy-find and jump to a live workspace with **Super+Ctrl+W**.
- See names directly in the Omarchy bar (`2:homeSource bug 123`).
- Click an inactive label to jump to it; click the active label (or right-click
  any label) to rename it.
- Keep names in Hyprland's own compositor-session state through the
  `renameworkspace` dispatcher. There is no second database to get stale.

Names intentionally last for the current Hyprland session. After logout/reboot,
workspaces begin unnamed again. This matches Hyprland's dynamic workspace model
and avoids resurrecting stale project names.

## Requirements

- Omarchy 4.x (developed against `4.0.0-1`)
- The stock Omarchy shell and Hyprland
- No extra packages; the fuzzy matcher is included

## Install from a published Git repository

```bash
omarchy plugin add https://github.com/YOUR-USER/omarchy-workspace-names.git --enable
omarchy plugin disable omarchy.workspaces
omarchy plugin enable workspace-names --section left
```

The first command reviews, clones, validates, and enables the plugin using
Omarchy's plugin manager. Disabling `omarchy.workspaces` prevents duplicate
stock number labels.

Add these lines to `~/.config/hypr/bindings.lua`. Omarchy assigns
`Super+Ctrl+W` to its Network panel by default, so the explicit `hl.unbind`
prevents both actions from firing on the same shortcut:

```lua
hl.unbind("SUPER + CTRL + W")
o.bind("SUPER + CTRL + W", "Find named workspace", "omarchy-shell shell summon workspace-names '{\"mode\":\"navigate\"}'")
o.bind("SUPER + CTRL + SHIFT + W", "Name current workspace", "omarchy-shell shell summon workspace-names '{\"mode\":\"edit\"}'")
```

Apply and verify the Hyprland configuration:

```bash
hyprctl reload
hyprctl configerrors
```

`configerrors` should produce no output.

## Local development runbook

These steps test this checkout without publishing it. Replace the path if the
repository lives elsewhere.

### 1. Run static and unit checks

```bash
cd /home/forbell/Sandbox/omarchy-workspace-names
omarchy plugin validate .
qmllint -I /usr/share/omarchy/shell BarWidget.qml WorkspacePicker.qml
node tests/fuzzy.test.js
```

Expected final line: `fuzzy tests: ok`. `omarchy plugin validate` and `qmllint`
are silent on success.

### 2. Install the local Git checkout

The plugin manager expects a Git URL. A `file://` URL exercises the same clone
and validation path as a future GitHub install:

```bash
omarchy plugin add file:///home/forbell/Sandbox/omarchy-workspace-names --enable
omarchy plugin disable omarchy.workspaces
omarchy plugin enable workspace-names --section left
```

If an earlier development copy is installed, remove it first:

```bash
omarchy plugin remove workspace-names
```

Then repeat the three installation commands above.

### 3. Add the keybindings

Append the `hl.unbind(...)` and two `o.bind(...)` lines from the installation section to
`~/.config/hypr/bindings.lua`, then run:

```bash
hyprctl reload
hyprctl configerrors
```

### 4. Manual acceptance test

1. Open windows on at least three workspaces.
2. On one workspace, press **Super+Ctrl+Shift+W**, enter `browser research`,
   and press Enter. Confirm its bar label changes immediately.
3. Name another workspace `homeSource bug 123`.
4. Press **Super+Ctrl+W**, type `bug123`, and press Enter. Confirm Hyprland jumps
   to the second workspace.
5. Open the picker and search by workspace number and monitor name.
6. Click an inactive bar label and confirm it becomes active.
7. Click the active label, erase its name, and press Enter. Confirm the bar
   returns to the numeric label.
8. Press Escape in both overlays and confirm no action occurs.

### 5. Iterate on the installed copy

Omarchy hot-reloads user plugin files. For a quick edit/test loop, edit the
installed checkout at:

```text
~/.config/omarchy/plugins/workspace-names/
```

To rescan or restart explicitly:

```bash
omarchy-shell shell rescanPlugins
omarchy restart shell
```

For changes made in this source repository, commit them, remove the installed
copy, and repeat the local `file://` installation to test the exact distributable
state.

## Usage details

| Action | Result |
|---|---|
| `Super+Ctrl+W` | Open fuzzy workspace navigation |
| `Super+Ctrl+Shift+W` | Rename the focused workspace |
| Type | Filter by name, number, or monitor |
| Up / Down | Change selection |
| Enter | Jump or save |
| Escape | Cancel |
| Click inactive bar label | Jump |
| Click active / right-click label | Rename |

## Design notes

The plugin calls Hyprland's `workspace` and `renameworkspace` dispatchers with
argument arrays (not shell-concatenated commands). Workspace names therefore
live in the compositor, and labels react through Quickshell's
`Hyprland.workspaces` model. Special workspaces and non-positive internal IDs
are excluded.

## Uninstall / restore stock behavior

```bash
omarchy plugin remove workspace-names
omarchy plugin enable omarchy.workspaces --section left
```

Remove the custom `hl.unbind(...)` and two `o.bind(...)` lines from
`~/.config/hypr/bindings.lua`, then run `hyprctl reload`.
