import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string jalaliDate: pluginData.jalaliDate
    Process {
            id: jdateProcess
            command: ["sh", "-c", "jdate | awk '{print $1,$2,$3}'"]
            running: true            
            stdout: SplitParser {
                onRead: (line) =>{ root.jalaliDate = line.trim()}
            }
    }

    horizontalBarPill: Component {
        Row {
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
    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn

            property var monthCalendar: []
            
Process {
    id: jcalProcess
    command: ["sh", "-c", "jcal"]
    running: true

    onStarted: {
        popoutColumn.monthCalendar = []
    }

    stdout: SplitParser {
        onRead: (line) => {
            if (!line) return

            let parts = line.trim().split(/\s+/)

            // 👇 مهم: آرایه جدید بساز (نه push)
            popoutColumn.monthCalendar =
                popoutColumn.monthCalendar.concat(parts)
        }
    }
}

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popoutColumn.headerHeight -
                               popoutColumn.detailsHeight - Theme.spacingXL

                DankGridView {
                    anchors.fill: parent
                    cellWidth: 50
                    cellHeight: 50
                    model: popoutColumn.monthCalendar

                    delegate: StyledRect {
                        width: 45
                        height: 45
                        radius: Theme.cornerRadius
                        color: emojiMouse.containsMouse ?
                               Theme.surfaceContainerHighest :
                               Theme.surfaceContainerHigh

                        StyledText {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Theme.fontSizeXLarge
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
