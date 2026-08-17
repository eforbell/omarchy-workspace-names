import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "workspace-names"

  function activeRows() {
    var rows = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (values[i].id > 0) rows.push(values[i])
    rows.sort(function(a, b) { return a.id - b.id })
    return rows
  }

  function displayName(workspace) {
    if (!workspace) return ""
    var name = String(workspace.name || "")
    return !name || name === String(workspace.id) ? String(workspace.id) : String(workspace.id) + ":" + name
  }

  // Match Omarchy Quattro's built-in workspaces widget exactly. Bar.run
  // routes through the bar host, while shellQuote preserves the Lua dispatcher
  // expression as one hyprctl argument.
  function focus(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch "
      + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function edit(id) {
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", "workspace-names",
      JSON.stringify({ mode: "edit", workspaceId: id })])
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: Style.space(1)

    Repeater {
      model: root.activeRows()

      WidgetButton {
        required property var modelData
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData.id

        bar: root.bar
        text: root.displayName(modelData)
        opacity: focused || modelData.toplevels.values.length > 0 ? 1 : 0.55
        horizontalMargin: 7
        verticalPadding: 6
        fixedHeight: root.barSize
        onPressed: function(button) {
          if (button === Qt.RightButton) root.edit(modelData.id)
          else root.focus(modelData.id)
        }
      }
    }
  }
}
