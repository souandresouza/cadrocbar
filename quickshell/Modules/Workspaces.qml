import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Widgets

Item {
	id: workspaces

	required property var screen

	readonly property var monitor: Hyprland.monitorFor(screen)

	height: Theme.contentHeight
	implicitWidth: row.implicitWidth

	Row {
		id: row
		spacing: 4
		anchors.verticalCenter: parent.verticalCenter

		Repeater {
			id: model
			model: Hyprland.workspaces

			delegate: ModuleButton {
				id: wsButton

				required property var modelData
				readonly property var ws: modelData

				width: 26
				height: Theme.contentHeight
				visible: wsButton.ws && workspaces.monitor && workspaces.monitor.activeWorkspace
					&& wsButton.ws.id === workspaces.monitor.activeWorkspace.id
				active: wsButton.ws && workspaces.monitor && workspaces.monitor.activeWorkspace
					&& wsButton.ws.id === workspaces.monitor.activeWorkspace.id
				urgent: wsButton.ws && wsButton.ws.urgent
				dim: false
				accentColor: Theme.accent

				IconText {
					// O content é injetado no contentRow do ModuleButton, então
					// "parent" aqui é o contentRow — usar o id do delegate.
					text: wsButton.ws ? String(wsButton.ws.id) : ""
					textColor: wsButton.active ? Theme.accent
						: wsButton.urgent ? Theme.danger
						: Theme.fg
				}

				onClicked: wsButton.ws && wsButton.ws.activate()
			}
		}
	}
}