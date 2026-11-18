import QtQuick
import Quickshell
import qs.Common
import qs.Widgets

// Abre/alterna o painel do swaync (daemon de notificações já em execução).
ModuleButton {
	id: root

	IconText {
		glyph: "\uf0f3"
		glyphColor: Theme.fg
	}

	onClicked: Quickshell.execDetached(["swaync-client", "-t"])
}
