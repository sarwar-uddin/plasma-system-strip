import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    // ---- configuration -------------------------------------------------
    readonly property int capacity: Math.max(20, Math.min(600, Plasmoid.configuration.historySeconds))
    readonly property string gpu: Plasmoid.configuration.gpuSensor || "gpu/gpu0"
    readonly property bool gpuClockMode: Plasmoid.configuration.gpuMetric === "clock"
    readonly property string disk: Plasmoid.configuration.diskSensor || "disk/all"
    readonly property string net: Plasmoid.configuration.networkSensor || "network/all"

    // ---- palette (rgb triplets for Canvas, hex for QML) ----------------
    readonly property string crimson: "224,32,63"
    readonly property string silver: "220,220,226"
    readonly property string steel: "124,124,132"
    readonly property color crimsonHex: "#E0203F"
    readonly property color silverHex: "#DCDCE2"
    readonly property color steelHex: "#7C7C84"

    // ---- history buffers -----------------------------------------------
    property var cpuHist: []
    property var ramHist: []
    property var gpuHist: []
    property var vramHist: []
    property var downHist: []
    property var upHist: []
    property var readHist: []
    property var writeHist: []

    // Units/sources change with these settings, so old samples would be wrong.
    onGpuClockModeChanged: gpuHist = []
    onGpuChanged: { gpuHist = []; vramHist = [] }
    onNetChanged: { downHist = []; upHist = [] }
    onDiskChanged: { readHist = []; writeHist = [] }

    function num(v) { return (typeof v === "number" && isFinite(v)) ? v : 0 }

    function push(arr, v) {
        const a = arr.slice(Math.max(0, arr.length - capacity + 1))
        a.push(num(v))
        return a
    }

    function fmtBytes(b) {
        b = Math.max(0, num(b))
        const u = ["B", "KiB", "MiB", "GiB", "TiB"]
        let i = 0
        while (b >= 1024 && i < u.length - 1) { b /= 1024; i++ }
        return (b >= 100 || i === 0 ? b.toFixed(0) : b.toFixed(1)) + " " + u[i]
    }
    function fmtRate(b) { return fmtBytes(b) + "/s" }
    function fmtGiB(b) { return (num(b) / 1073741824).toFixed(1) }
    // Busy % in usage mode; core clock (MHz) in clock mode.
    function gpuLoad() {
        return gpuClockMode ? num(gpuF.value) : num(gpuU.value)
    }
    // ksystemstats reports GPU clocks in MHz
    function fmtMHz(v) {
        v = num(v)
        return v >= 1000 ? (v / 1000).toFixed(2) + " GHz" : Math.round(v) + " MHz"
    }

    function pct(v) { return Math.round(num(v)) + "%" }

    // ---- sensors -------------------------------------------------------
    Sensors.Sensor { id: cpu;    sensorId: "cpu/all/usage";                updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuT;   sensorId: "cpu/all/averageTemperature";   updateRateLimit: 2000 }
    Sensors.Sensor { id: ram;    sensorId: "memory/physical/usedPercent";  updateRateLimit: 1000 }
    Sensors.Sensor { id: ramU;   sensorId: "memory/physical/used";         updateRateLimit: 2000 }
    Sensors.Sensor { id: ramT;   sensorId: "memory/physical/total";        updateRateLimit: 10000 }
    Sensors.Sensor { id: gpuU;   sensorId: root.gpu + "/usage";            updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuF;   sensorId: root.gpuClockMode ? root.gpu + "/coreFrequency" : ""; updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuT;   sensorId: root.gpu + "/temperature";      updateRateLimit: 2000 }
    Sensors.Sensor { id: vramP;  sensorId: root.gpu + "/usedPercent";      updateRateLimit: 1000 }
    Sensors.Sensor { id: vramU;  sensorId: root.gpu + "/usedVram";         updateRateLimit: 2000 }
    Sensors.Sensor { id: vramT;  sensorId: root.gpu + "/totalVram";        updateRateLimit: 10000 }
    Sensors.Sensor { id: down;   sensorId: root.net + "/download";         updateRateLimit: 1000 }
    Sensors.Sensor { id: up;     sensorId: root.net + "/upload";           updateRateLimit: 1000 }
    Sensors.Sensor { id: dRead;  sensorId: root.disk + "/read";            updateRateLimit: 1000 }
    Sensors.Sensor { id: dWrite; sensorId: root.disk + "/write";           updateRateLimit: 1000 }
    Sensors.Sensor { id: dUsed;  sensorId: root.disk + "/usedPercent";     updateRateLimit: 10000 }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            root.cpuHist = root.push(root.cpuHist, cpu.value)
            root.ramHist = root.push(root.ramHist, ram.value)
            root.gpuHist = root.push(root.gpuHist, root.gpuLoad())
            root.vramHist = root.push(root.vramHist, vramP.value)
            root.downHist = root.push(root.downHist, down.value)
            root.upHist = root.push(root.upHist, up.value)
            root.readHist = root.push(root.readHist, dRead.value)
            root.writeHist = root.push(root.writeHist, dWrite.value)
        }
    }

    // Full charts on the desktop; mini sparklines + popup when placed in a panel.
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    switchWidth: Kirigami.Units.gridUnit * 20
    switchHeight: Kirigami.Units.gridUnit * 12
    toolTipMainText: i18n("System Strip")
    toolTipSubText: i18n("CPU %1 · RAM %2 · GPU %3", pct(cpu.value), pct(ram.value), gpuClockMode ? fmtMHz(gpuF.value) : pct(gpuU.value))

    compactRepresentation: MouseArea {
        id: compact
        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Layout.minimumWidth: vertical ? -1 : miniRow.implicitWidth
        Layout.preferredWidth: vertical ? -1 : miniRow.implicitWidth
        Layout.maximumWidth: vertical ? Infinity : miniRow.implicitWidth

        // Vertical panels are too narrow for sparklines: fall back to the icon.
        Kirigami.Icon {
            anchors.fill: parent
            visible: compact.vertical
            source: Plasmoid.icon
            active: compact.containsMouse
        }

        RowLayout {
            id: miniRow
            visible: !compact.vertical
            anchors.verticalCenter: parent.verticalCenter
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [
                    { label: "CPU", data: root.cpuHist, rgb: root.crimson, value: cpu.value },
                    { label: "RAM", data: root.ramHist, rgb: root.silver, value: ram.value }
                ]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 3
                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                        Layout.preferredHeight: Math.max(12, compact.height - 6)
                        radius: 2
                        color: "#0D0D0F"
                        border.color: "#2A2A2E"
                        Sparkline {
                            anchors.fill: parent
                            anchors.margins: 2
                            values: modelData.data
                            rgb: modelData.rgb
                        }
                    }
                    PC3.Label {
                        text: root.pct(modelData.value)
                        font: Kirigami.Theme.smallFont
                        // fixed width so the panel doesn't jitter as digits change
                        Layout.preferredWidth: tm.advanceWidth
                        horizontalAlignment: Text.AlignRight
                        TextMetrics { id: tm; font: Kirigami.Theme.smallFont; text: "100%" }
                    }
                }
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 26
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        Layout.preferredWidth: 620
        Layout.preferredHeight: 360

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                PC3.Label { text: i18n("System") }
                Item { Layout.fillWidth: true }
                PC3.Label {
                    visible: root.num(cpuT.value) > 0
                    text: i18n("CPU %1°C", Math.round(root.num(cpuT.value)))
                    color: root.num(cpuT.value) >= 85 ? root.crimsonHex : Kirigami.Theme.textColor
                }
                PC3.Label {
                    visible: root.num(gpuT.value) > 0
                    text: i18n("GPU %1°C", Math.round(root.num(gpuT.value)))
                    color: root.num(gpuT.value) >= 85 ? root.crimsonHex : Kirigami.Theme.textColor
                }
                PC3.Label {
                    text: i18n("last %1s", root.capacity)
                    opacity: 0.6
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Quadrant {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.preferredWidth: 1; Layout.preferredHeight: 1
                    capacity: root.capacity
                    fixedMax: 100
                    readouts: [
                        { label: "CPU", value: root.pct(cpu.value), color: root.crimsonHex },
                        { label: "RAM", value: root.fmtGiB(ramU.value) + "/" + root.fmtGiB(ramT.value) + " GiB", color: root.silverHex }
                    ]
                    series: [
                        { data: root.ramHist, rgb: root.silver, fill: false },
                        { data: root.cpuHist, rgb: root.crimson, fill: true }
                    ]
                }

                Quadrant {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.preferredWidth: 1; Layout.preferredHeight: 1
                    capacity: root.capacity
                    fixedMax: root.gpuClockMode ? -1 : 100
                    minScale: 400
                    labelFormatter: root.gpuClockMode ? function (v) { return root.fmtMHz(v) }
                                                      : function (v) { return Math.round(v) + "%" }
                    readouts: [
                        { label: "GPU", value: root.gpuClockMode ? root.fmtMHz(gpuF.value) : root.pct(gpuU.value), color: root.crimsonHex },
                        { label: "VRAM", value: root.num(vramT.value) > 0
                              ? root.fmtBytes(vramU.value) + "/" + root.fmtBytes(vramT.value)
                              : root.pct(vramP.value), color: root.silverHex }
                    ]
                    // VRAM % shares the axis only in usage mode
                    series: root.gpuClockMode
                        ? [ { data: root.gpuHist, rgb: root.crimson, fill: true } ]
                        : [ { data: root.vramHist, rgb: root.silver, fill: false },
                            { data: root.gpuHist, rgb: root.crimson, fill: true } ]
                }

                Quadrant {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.preferredWidth: 1; Layout.preferredHeight: 1
                    capacity: root.capacity
                    gridRows: 2
                    minScale: 10240
                    labelFormatter: function (v) { return root.fmtBytes(v) }
                    readouts: [
                        { label: "↓", value: root.fmtRate(down.value), color: root.crimsonHex },
                        { label: "↑", value: root.fmtRate(up.value), color: root.steelHex }
                    ]
                    series: [
                        { data: root.upHist, rgb: root.steel, fill: false },
                        { data: root.downHist, rgb: root.crimson, fill: true }
                    ]
                }

                Quadrant {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.preferredWidth: 1; Layout.preferredHeight: 1
                    capacity: root.capacity
                    gridRows: 2
                    minScale: 10240
                    labelFormatter: function (v) { return root.fmtBytes(v) }
                    readouts: [
                        { label: "R", value: root.fmtRate(dRead.value), color: root.crimsonHex },
                        { label: "W", value: root.fmtRate(dWrite.value), color: root.steelHex },
                        { label: "Used", value: root.pct(dUsed.value), color: root.silverHex }
                    ]
                    series: [
                        { data: root.writeHist, rgb: root.steel, fill: false },
                        { data: root.readHist, rgb: root.crimson, fill: true }
                    ]
                }
            }
        }
    }
}
