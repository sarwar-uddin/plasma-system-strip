import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_gpuSensor: gpuField.text
    property string cfg_gpuMetric
    property alias cfg_diskSensor: diskField.text
    property alias cfg_networkSensor: netField.text
    property alias cfg_historySeconds: historySpin.value

    Kirigami.FormLayout {
        QQC2.TextField {
            id: gpuField
            Kirigami.FormData.label: i18n("GPU:")
            placeholderText: "gpu/gpu0"
        }
        QQC2.Label {
            text: i18n("Use gpu/gpu1 etc. for a second GPU. On hybrid laptops, watching the discrete NVIDIA GPU keeps it powered on.")
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
        QQC2.ComboBox {
            id: metricBox
            Kirigami.FormData.label: i18n("GPU chart shows:")
            model: [i18n("Usage (busy %)"), i18n("Core clock")]
            currentIndex: cfg_gpuMetric === "clock" ? 1 : 0
            onActivated: index => cfg_gpuMetric = (index === 1 ? "clock" : "usage")
        }
        QQC2.Label {
            text: i18n("Some AMD APUs (e.g. Raven/Picasso) report a stuck 100% busy value; core clock tracks load on those.")
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
        QQC2.TextField {
            id: diskField
            Kirigami.FormData.label: i18n("Disk:")
            placeholderText: "disk/all"
        }
        QQC2.TextField {
            id: netField
            Kirigami.FormData.label: i18n("Network:")
            placeholderText: "network/all"
        }
        QQC2.SpinBox {
            id: historySpin
            Kirigami.FormData.label: i18n("History (seconds):")
            from: 20
            to: 600
            stepSize: 10
        }
    }
}
