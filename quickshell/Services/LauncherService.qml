pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Widgets

Singleton {
	id: launcher

	property var entries: []
	property var query: ""
	property var wal: ({})

	function hexColor(hex, alpha) {
		const c = /^#?([0-9a-f]{6})/i.exec(hex || "");
		if (!c)
			return Theme.popupBg;
		return Qt.rgba(
			parseInt(c[1].substr(0, 2), 16) / 255,
			parseInt(c[1].substr(2, 2), 16) / 255,
			parseInt(c[1].substr(4, 2), 16) / 255,
			alpha === undefined ? 1 : alpha);
	}

	readonly property color cardBg: launcher.wal.background
		? launcher.hexColor(launcher.wal.background, 0.97)
		: Qt.rgba(Theme.popupBg.r, Theme.popupBg.g, Theme.popupBg.b, 0.97)
	readonly property color cardBorder: launcher.wal.color4
		? launcher.hexColor(launcher.wal.color4, 0.6)
		: Theme.popupBorder
	readonly property color fgColor: launcher.wal.foreground
		? launcher.hexColor(launcher.wal.foreground, 1)
		: Theme.fg
	readonly property color fgDim: launcher.wal.foreground
		? launcher.hexColor(launcher.wal.foreground, 0.6)
		: Theme.stone
	readonly property color accentColor: launcher.wal.color2
		? launcher.hexColor(launcher.wal.color2, 1)
		: Theme.accent
	readonly property color rowColor: launcher.wal.color1
		? launcher.hexColor(launcher.wal.color1, 1)
		: Theme.moduleHover
	readonly property color inputBg: launcher.wal.color0
		? launcher.hexColor(launcher.wal.color0, 0.5)
		: Theme.moduleHover

	readonly property var filtered: launcher.buildResults(query)

	readonly property var searchEngines: [
		{ prefix: "g", name: "Google", url: "https://www.google.com/search?q=" },
		{ prefix: "yt", name: "YouTube", url: "https://www.youtube.com/results?search_query=" },
		{ prefix: "w", name: "Wikipedia", url: "https://en.wikipedia.org/w/index.php?search=" },
		{ prefix: "gh", name: "GitHub", url: "https://github.com/search?q=" },
		{ prefix: "ddg", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=" }
	]

	function glyphFor(entry) {
		const n = ((entry.name || "") + " " + (entry.icon || "")).toLowerCase();
		if (n.includes("firefox") || n.includes("browser") || n.includes("web") || n.includes("chrom"))
			return "\uf0ac";
		if (n.includes("terminal") || n.includes("kitty") || n.includes("console") || n.includes("btop"))
			return "\uf120";
		if (n.includes("vscode") || n.includes("code") || n.includes("electron") || n.includes("idea"))
			return "\uf121";
		if (n.includes("discord") || n.includes("telegram") || n.includes("whatsapp") || n.includes("slack") || n.includes("zoom") || n.includes("chat"))
			return "\uf086";
		if (n.includes("spotify") || n.includes("music") || n.includes("rhythmbox"))
			return "\uf001";
		if (n.includes("calculator") || n.includes("gnome-calc"))
			return "\uf0e7";
		if (n.includes("gimp") || n.includes("inkscape") || n.includes("image") || n.includes("photo") || n.includes("pixel"))
			return "\uf03e";
		if (n.includes("files") || n.includes("nautilus") || n.includes("thunar") || n.includes("dolphin") || n.includes("file"))
			return "\uf07b";
		if (n.includes("settings") || n.includes("control")) 
			return "\uf013";
		if (n.includes("lock") || n.includes("screen"))
			return "\uf023";
		return "\uf0ae";
	}

	function parseExec(exec) {
		const tokens = [];
		const re = /"([^"]*)"|'([^']*)'|\S+/g;
		const raw = (exec || "").replace(/%[a-zA-Z%]/g, "").trim();
		let m;
		while ((m = re.exec(raw)) !== null)
			tokens.push(m[1] !== undefined ? m[1] : m[2] !== undefined ? m[2] : m[0]);
		return tokens;
	}

	function findEngine(token) {
		const needle = String(token || "").toLowerCase();
		for (let i = 0; i < searchEngines.length; i++)
			if (searchEngines[i].prefix === needle)
				return searchEngines[i];
		return null;
	}

	// O prefixo só vira busca web quando há espaço depois dele, para que
	// digitar "w" continue encontrando apps normalmente.
	function engineForQuery(text) {
		const parts = String(text || "").replace(/^\s+/, "").split(/\s+/);
		if (parts.length < 2)
			return null;
		return findEngine(parts[0]);
	}

	function appResult(entry) {
		return {
			type: "app",
			name: entry.name,
			comment: entry.comment || "",
			icon: entry.icon || "",
			glyph: launcher.glyphFor(entry),
			exec: entry.exec,
			terminal: !!entry.terminal
		};
	}

	function buildResults(text) {
		const q = String(text || "").trim();
		let out = [];

		if (!q)
			return entries.map(e => launcher.appResult(e));

		if (q.startsWith(">")) {
			const term = q.substring(1).trim();
			if (term.length > 0)
				out.push({
					type: "run",
					name: term,
					comment: "Executar no terminal",
					glyph: "\uf120",
					command: term
				});
			return out;
		}

		// Calculadora: apenas expressões reais, nunca um número sozinho.
		if (MathEval.isExpression(q)) {
			const formatted = MathEval.format(MathEval.evaluate(q));
			if (formatted !== "")
				out.push({
					type: "calculator",
					name: q + " = " + formatted,
					comment: "Copiar resultado",
					glyph: "\uf0e7",
					value: formatted
				});
		}

		const engine = launcher.engineForQuery(q);
		if (engine) {
			const parts = q.replace(/^\s+/, "").split(/\s+/);
			const search = parts.slice(1).join(" ").trim();
			if (search) {
				const url = engine.url + encodeURIComponent(search);
				out.push({
					type: "search",
					name: "Buscar no " + engine.name + ": " + search,
					comment: url,
					glyph: "\uf0ac",
					url: url
				});
			}
		} else {
			const lower = q.toLowerCase();
			out = out.concat(entries
				.filter(e => ((e.name || "") + " " + (e.comment || "")).toLowerCase().includes(lower))
				.map(e => launcher.appResult(e)));
		}

		return out;
	}

	function launch(entry) {
		if (!entry)
			return;

		if (entry.type === "calculator") {
			Quickshell.execDetached(["wl-copy", "--", String(entry.value)]);
			launcher.close();
			return;
		}

		if (entry.type === "search") {
			Quickshell.execDetached(["xdg-open", entry.url]);
			launcher.close();
			return;
		}

		if (entry.type === "run") {
			const term = Quickshell.env("CADROCBAR_TERMINAL", "kitty");
			Quickshell.execDetached([term, "-e", "sh", "-c", entry.command]);
			launcher.close();
			return;
		}

		const argv = launcher.parseExec(entry.exec);
		if (argv.length === 0)
			argv.push(entry.name || "sh");
		const terminal = Quickshell.env("CADROCBAR_TERMINAL", "kitty");
		const args = entry.terminal ? [terminal, "-e"].concat(argv) : argv;
		Quickshell.execDetached(args);
		launcher.close();
	}

	function open(screen) {
		if (screen) {
			popupWindow.screen = screen;
			card.sf = Math.max(0.75, Math.round((screen.height / Theme.referenceHeight) * 100) / 100);
		}
		entriesProcess.exec([Theme.binDir + "/launcher.py"]);
		launcher.query = "";
		popupWindow.visible = true;
		queryInput.forceActiveFocus();
		resultList.currentIndex = 0;
	}

	function toggleApps(screen) {
		launcher.toggle(screen);
	}

	function close() {
		popupWindow.visible = false;
	}

	function toggle(screen) {
		if (popupWindow.visible)
			launcher.close();
		else
			launcher.open(screen);
	}

	Timer {
		interval: 300
		repeat: false
		running: true
		onTriggered: entriesProcess.exec([Theme.binDir + "/launcher.py"])
	}

	Process {
		id: entriesProcess

		running: false
		stdout: StdioCollector {
			id: coll
			waitForEnd: true
		}

		onExited: () => {
			const line = coll.text.toString().trim();
			if (line.length === 0)
				return;
			try {
				const j = JSON.parse(line);
				if (j && Array.isArray(j.entries))
					launcher.entries = j.entries;
				if (j && j.wal && j.wal.background) {
					launcher.wal = j.wal;
					console.log("WAL set");
				}
			} catch (e) { console.warn("[launcher] falha ao parsear output:", e.message); }
		}
	}

	IpcHandler {
		target: "launcher"

		function toggleApps(): void {
			launcher.toggleApps(Quickshell.screens[0]);
		}

		function isOpen(): bool {
			return popupWindow.visible;
		}

		function search(query: string): string {
			return JSON.stringify(launcher.buildResults(query));
		}
	}

	PanelWindow {
		id: popupWindow
		visible: false
		color: "transparent"

		WlrLayershell.namespace: "cadrocbar:launcher"
		WlrLayershell.layer: WlrLayershell.Overlay
		WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

		anchors {
			top: true
			bottom: true
			left: true
			right: true
		}

		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(0, 0, 0, 0.4)

			MouseArea {
				anchors.fill: parent
				onClicked: launcher.close()
			}
		}

Rectangle {
					id: card
					property real sf: 1
					width: Theme.roundScaled(560, card.sf)
					height: Theme.roundScaled(520, card.sf)
					radius: Theme.popupRadius
					color: launcher.cardBg
					border.width: 1
					border.color: launcher.cardBorder
					anchors.centerIn: parent

					Keys.onPressed: (event) => {
						if (event.key === Qt.Key_Escape)
							launcher.close();
					}

			Column {
				anchors.fill: parent
				anchors.margins: Theme.roundScaled(14, card.sf)
				spacing: Theme.roundScaled(10, card.sf)

Rectangle {
						width: parent.width
						height: Theme.roundScaled(42, card.sf)
						radius: Theme.moduleRadius
						color: launcher.inputBg

						Text {
							visible: launcher.query.length === 0
							text: "Apps · conta · g/yt/w/gh/ddg · > comando"
							color: launcher.fgDim
							font.family: Theme.fontFamily
							font.pixelSize: Theme.roundScaled(Theme.fontSizeLarge, card.sf)
							anchors.fill: parent
							anchors.leftMargin: Theme.roundScaled(12, card.sf)
							anchors.rightMargin: Theme.roundScaled(12, card.sf)
							verticalAlignment: Text.AlignVCenter
						}

						TextInput {
							id: queryInput
							anchors.fill: parent
							anchors.leftMargin: Theme.roundScaled(12, card.sf)
							anchors.rightMargin: Theme.roundScaled(12, card.sf)
							verticalAlignment: Text.AlignVCenter
							font.family: Theme.fontFamily
							font.pixelSize: Theme.roundScaled(Theme.fontSizeLarge, card.sf)
							color: launcher.fgColor
							selectionColor: launcher.accentColor
							selectedTextColor: launcher.fgColor
							text: launcher.query
							onTextChanged: launcher.query = text
						Keys.onPressed: (event) => {
							if (event.key === Qt.Key_Down) {
								resultList.currentIndex = Math.min(resultList.currentIndex + 1, resultList.count - 1);
								event.accepted = true;
							} else if (event.key === Qt.Key_Up) {
								resultList.currentIndex = Math.max(resultList.currentIndex - 1, 0);
								event.accepted = true;
							} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
								launcher.launch(resultList.currentItem && resultList.currentItem.entry);
								event.accepted = true;
							} else if (event.key === Qt.Key_Tab) {
								const e = resultList.currentItem && resultList.currentItem.entry;
								if (e)
									launcher.query = e.type === "calculator" ? String(e.value) : e.name;
								event.accepted = true;
							} else if (event.key === Qt.Key_Escape) {
								launcher.close();
								event.accepted = true;
							}
						}
					}
				}

				ListView {
					id: resultList
					width: parent.width
					height: parent.height - Theme.roundScaled(52, card.sf)
					clip: true
					model: launcher.filtered
					spacing: Theme.roundScaled(2, card.sf)
					currentIndex: 0

					delegate: Rectangle {
						required property var modelData
						width: ListView.view.width
						height: Theme.roundScaled(46, card.sf)
						radius: Theme.moduleRadius
						color: ListView.isCurrentItem ? launcher.rowColor : "transparent"

						property var entry: modelData

						Row {
							anchors.fill: parent
							anchors.margins: Theme.roundScaled(8, card.sf)
							spacing: Theme.roundScaled(10, card.sf)

							IconText {
								glyph: modelData.glyph || launcher.glyphFor(modelData)
								glyphColor: launcher.accentColor
								width: Theme.roundScaled(24, card.sf)
							}

							Column {
								width: parent.width - Theme.roundScaled(34, card.sf)
								anchors.verticalCenter: parent.verticalCenter
								spacing: 2

								Text {
									width: parent.width
									text: modelData.name
									font.family: Theme.fontFamily
									font.pixelSize: Theme.roundScaled(Theme.fontSize, card.sf)
									font.weight: Font.DemiBold
									color: launcher.fgColor
									elide: Text.ElideRight
								}

								Text {
									width: parent.width
									text: modelData.comment
									font.family: Theme.fontFamily
									font.pixelSize: Theme.roundScaled(Theme.fontSizeSmall, card.sf)
									color: launcher.fgDim
									elide: Text.ElideRight
									visible: modelData.comment.length > 0
								}
							}
						}

						MouseArea {
							anchors.fill: parent
							onClicked: launcher.launch(modelData)
							onEntered: resultList.currentIndex = index
						}
					}
				}
			}
		}
	}
}