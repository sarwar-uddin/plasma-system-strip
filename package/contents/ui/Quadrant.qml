import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

// One titled chart cell: a legend row of colored readouts above a HistoryChart.
ColumnLayout {
    id: quad

    // [{ label: "CPU", value: "12%", color: "#E0203F" }]
    property var readouts: []
    property alias series: chart.series
    property alias fixedMax: chart.fixedMax
    property alias minScale: chart.minScale
    property alias labelFormatter: chart.labelFormatter
    property alias gridRows: chart.gridRows
    property alias capacity: chart.capacity

    spacing: 2

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Repeater {
            model: quad.readouts
            delegate: RowLayout {
                required property var modelData
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    implicitWidth: 3
                    implicitHeight: valueLabel.implicitHeight * 0.85
                    color: modelData.color
                }
                PC3.Label {
                    text: modelData.label
                    opacity: 0.7
                    font: Kirigami.Theme.smallFont
                }
                PC3.Label {
                    id: valueLabel
                    text: modelData.value
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.DemiBold
                }
            }
        }
        Item { Layout.fillWidth: true }
    }

    HistoryChart {
        id: chart
        Layout.fillWidth: true
        Layout.fillHeight: true
        labelWidth: 46
        gridColEvery: 15
    }
}
