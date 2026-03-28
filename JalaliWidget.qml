import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // 1. The Property you want to be live
    property string jalaliDate: pluginData.jalaliDate
    Process {
            id: jdateProcess
            command: ["sh", "-c", "jdate | awk '{print $1,$2,$3}'"]
            running: true            
            stdout: SplitParser {
                onRead: (line) =>{ root.jalaliDate = line.trim()}
            }
    }

    // 3. The Heartbeat: Refresh every 60 seconds
//    Timer {
//        interval: 60000
//        running: true
//        repeat: true
//        triggeredOnStart: true
//        onTriggered: jdateProcess.start()
//    }

    // 4. The Bar Pill (The Name of the Widget)
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
}
