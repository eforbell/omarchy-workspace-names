import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "Fuzzy.js" as Fuzzy

Item {
  id: root
  property var shell: null
  property var manifest: null
  property bool opened: false
  property string mode: "navigate"
  property string filterText: ""
  property int editWorkspaceId: -1
  property int selectedIndex: 0
  property var rows: []
  property var filteredRows: []

  function allRows() {
    var result = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      if (ws.id <= 0) continue
      result.push({ id: ws.id, name: String(ws.name || ""), monitor: ws.monitor ? String(ws.monitor.name || "") : "" })
    }
    result.sort(function(a, b) { return a.id - b.id })
    return result
  }

  function currentId() {
    return Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
  }

  function meaningfulName(row) {
    return row && row.name !== String(row.id) ? row.name : ""
  }

  function open(payloadJson) {
    var payload = {}
    try { payload = payloadJson ? JSON.parse(payloadJson) : {} } catch (error) { payload = {} }
    root.mode = payload.mode === "edit" ? "edit" : "navigate"
    root.editWorkspaceId = Number(payload.workspaceId || root.currentId())
    root.rows = root.allRows()
    if (root.mode === "edit") {
      var target = null
      for (var i = 0; i < root.rows.length; i++) if (root.rows[i].id === root.editWorkspaceId) target = root.rows[i]
      root.filterText = root.meaningfulName(target)
    } else root.filterText = ""
    root.selectedIndex = 0
    root.rebuild()
    root.opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() { root.opened = false }
  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function") root.shell.hide("workspace-names")
  }
  function toggle(payloadJson) { if (root.opened) root.dismiss(); else root.open(payloadJson || "{}") }

  function rebuild() {
    root.filteredRows = root.mode === "navigate" ? Fuzzy.filter(root.filterText, root.rows) : []
    if (root.selectedIndex >= root.filteredRows.length) root.selectedIndex = Math.max(0, root.filteredRows.length - 1)
  }

  function setText(value) { root.filterText = value; root.selectedIndex = 0; root.rebuild() }
  function move(delta) {
    if (!root.filteredRows.length) return
    root.selectedIndex = (root.selectedIndex + delta + root.filteredRows.length) % root.filteredRows.length
    results.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }
  function submit() {
    if (root.mode === "edit") {
      Quickshell.execDetached(["hyprctl", "dispatch", "renameworkspace", String(root.editWorkspaceId), root.filterText.trim()])
      root.dismiss()
      return
    }
    if (!root.filteredRows.length) return
    var id = root.filteredRows[root.selectedIndex].id
    root.dismiss()
    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(id)])
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "workspace-names"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle { anchors.fill: parent; color: Color.menu.scrim }
    MouseArea { anchors.fill: parent; onClicked: root.dismiss() }

    BorderSurface {
      id: card
      width: Math.min(Style.space(440), panel.width - Style.gapsOut * 2)
      height: root.mode === "edit" ? Style.space(150) : Math.min(Style.space(470), panel.height - Style.gapsOut * 2)
      anchors.centerIn: parent
      radius: Style.cornerRadius
      color: Color.menu.background
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
      padding: Style.spacing.panelPadding
      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) { root.dismiss(); event.accepted = true }
          else if (event.key === Qt.Key_Up) { root.move(-1); event.accepted = true }
          else if (event.key === Qt.Key_Down) { root.move(1); event.accepted = true }
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.submit(); event.accepted = true }
          else if (Util.editsFilter(event, root.filterText)) { root.setText(Util.editedFilter(event, root.filterText)); event.accepted = true }
          else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setText(root.filterText + event.text); event.accepted = true
          }
        }

        Column {
          anchors.fill: parent
          anchors.margins: Style.spacing.panelPadding
          spacing: Style.spacing.md

          Text {
            text: root.mode === "edit" ? "Name workspace " + root.editWorkspaceId : "Jump to workspace"
            color: Color.menu.text
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.title
          }
          Rectangle {
            width: parent.width
            height: Style.space(42)
            radius: Style.cornerRadius
            color: Color.menu.selectedBackground
            Text {
              anchors.fill: parent; anchors.margins: Style.spacing.md
              verticalAlignment: Text.AlignVCenter
              text: root.filterText + "▏"
              color: Color.menu.selectedText
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }
          }
          Text {
            visible: root.mode === "edit"
            text: "Enter saves · empty restores the numeric label · Esc cancels"
            color: Color.menu.text
            opacity: 0.65
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.caption
          }
          ListView {
            id: results
            visible: root.mode === "navigate"
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: Style.spacing.xs
            model: root.filteredRows
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: results.width
              height: Style.space(44)
              radius: Style.cornerRadius
              color: index === root.selectedIndex ? Color.menu.selectedBackground : "transparent"
              Text {
                anchors.fill: parent; anchors.margins: Style.spacing.md
                verticalAlignment: Text.AlignVCenter
                text: modelData.id + "  " + (root.meaningfulName(modelData) || "(unnamed)") + (modelData.monitor ? "   · " + modelData.monitor : "")
                color: index === root.selectedIndex ? Color.menu.selectedText : Color.menu.text
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }
              MouseArea { anchors.fill: parent; onClicked: { root.selectedIndex = index; root.submit() } }
            }
          }
        }
      }
    }
  }
}
