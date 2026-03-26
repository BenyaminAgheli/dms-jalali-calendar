import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "shamsi-calendar"

    property string jalaliDate: "1405/01/06" 

    horizontalBarPill: Component {
        Row {
            id: horizontalRow
            spacing: 8
            
            DankIcon {
                name: "event"
                size: 14
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.jalaliDate
                font.pixelSize: 13
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 4
            anchors.horizontalCenter: parent.horizontalCenter
            
            DankIcon {
                name: "event"
                size: 16
                color: Theme.primary
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.jalaliDate
                font.pixelSize: 11
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }


    Component.onCompleted: {
        console.log("Jalali Widget Loaded");
    }
}
