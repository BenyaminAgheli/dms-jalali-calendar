import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string jalaliDate: ""
    property string currentDay: ""

    Process {
        id: jdateProcess
        command: ["sh", "-c", "jdate | awk '{print $1,$2,$3}'"]
        running: true
        stdout: SplitParser {
            onRead: (line) => { root.jalaliDate = line.trim() }
        }
    }

    Process {
        id: todayProcess
        command: ["sh", "-c", "jdate | awk '{print $3}'"]
        running: true
        stdout: SplitParser {
            onRead: (line) => { root.currentDay = line.trim() }
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

            property var monthDays: []
            property string monthTitle: ""
            property var weekDays: ["ش", "ی", "د", "س", "چ", "پ", "ج"]
            
            property int lineIndex: 0
            property bool isFirstWeek: true

            Process {
                id: jcalProcess
                command: ["sh", "-c", "jcal"]
                running: true

                onStarted: {
                    popoutColumn.monthDays = []
                    popoutColumn.monthTitle = ""
                    popoutColumn.lineIndex = 0
                    popoutColumn.isFirstWeek = true
                }

                stdout: SplitParser {
                    onRead: (line) => {
                        if (!line) return

                        let raw = line
                        let clean = raw.replace(/\x1b\[[0-9;]*m/g, "").replace(/\n$/, "")

                        if (popoutColumn.lineIndex === 0) {
                            popoutColumn.monthTitle = clean.trim()
                        }
                        else if (popoutColumn.lineIndex >= 2) {
                            let row = []

                            if (popoutColumn.isFirstWeek) {
                                let firstDigitIdx = clean.search(/\d/)
                                if (firstDigitIdx !== -1) {
                                    let padding = Math.floor(firstDigitIdx / 3)
                                    for (let i = 0; i < padding; i++) {
                                        row.push({ day: "", isHoliday: false })
                                    }
                                    popoutColumn.isFirstWeek = false
                                }
                            }

                            let parts = clean.trim().split(/\s+/)
                            for (let part of parts) {
                                if (!part) continue
                                let regex = new RegExp("\\x1b\\[[0-9;]*31m\\s*" + part)
                                let isHoliday = regex.test(raw)
                                row.push({ day: part, isHoliday: isHoliday })
                            }

                            popoutColumn.monthDays = popoutColumn.monthDays.concat(row)
                        }

                        popoutColumn.lineIndex++
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight
                                - popoutColumn.headerHeight
                                - popoutColumn.detailsHeight
                                - Theme.spacingXL

                Column {
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter

                    StyledText {
                        text: popoutColumn.monthTitle
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Row {
                        spacing: 0
                        width: 48 * 7
                        layoutDirection: Qt.RightToLeft 
                        
                        Repeater {
                            model: popoutColumn.weekDays
                            delegate: StyledText {
                                text: modelData
                                width: 48
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 12
                                color: Theme.primary
                            }
                        }
                    }

                    // Calendar Grid
                    DankGridView {
                        width: 48 * 7 
                        height: 48 * 6
                        cellWidth: 48
                        cellHeight: 48
                        model: popoutColumn.monthDays
                        layoutDirection: Qt.RightToLeft

                        delegate: StyledRect {
                            width: 44
                            height: 44
                            radius: 22

                            property bool isEmpty: modelData.day === ""
                            property bool isToday: modelData.day === root.currentDay

                            color: {
                                if (isEmpty) return "transparent";
                                if (isToday) return Theme.primary; 
                                return "transparent";
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.day
                                visible: !isEmpty

                                color: {
                                    if (isToday) return Theme.onPrimary;
                                    if (modelData.isHoliday) return Theme.error;
                                    
                                    return Theme.surfaceVariantText; 
                                }
                                font.bold: isToday
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: parent.opacity = 0.7
                                onExited: parent.opacity = 1.0
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 370
}
