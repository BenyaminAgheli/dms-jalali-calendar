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
    property string selectedDay: ""
    property string daysWithNotes: ""
    
    property bool isDetailsView: false
    property var dayNotesList: []

    // 1. دریافت تاریخ
    Process {
        id: jdateProcess
        command: ["sh", "-c", "jdate | awk '{print $1,$2,$3}'"]
        running: true
        stdout: SplitParser { onRead: (line) => { root.jalaliDate = line.trim() } }
    }

    Process {
        id: todayProcess
        command: ["sh", "-c", "jdate | awk '{print $3}'"]
        running: true
        stdout: SplitParser { onRead: (line) => { root.currentDay = line.trim() } }
    }

    // 2. بررسی روزهای دارای یادداشت
    Process {
        id: checkNotesProcess
        command: ["sh", "-c", "mkdir -p ~/.local/share/jalali_reminders && ls ~/.local/share/jalali_reminders/ | grep -oP 'day_\\K[0-9]+' | tr '\\n' ','"]
        running: true
        stdout: SplitParser { onRead: (line) => { root.daysWithNotes = line.trim() } }
    }

    // 3. خواندن یادداشت‌ها
    Process {
        id: readNotesProcess
        property var tempList: []
        command: ["sh", "-c", "cat ~/.local/share/jalali_reminders/day_" + root.selectedDay + ".txt 2>/dev/null"]
        onStarted: tempList = []
        stdout: SplitParser {
            onRead: (line) => { 
                if (line.trim() !== "") readNotesProcess.tempList.push(line.trim());
            }
        }
        onExited: root.dayNotesList = tempList
    }

    // 4. ذخیره یادداشت
    Process {
        id: saveProcess
        property string reminderText: ""
        command: [
            "sh", "-c", 
            "echo '" + reminderText + "' >> ~/.local/share/jalali_reminders/day_" + root.selectedDay + ".txt"
        ]
        onExited: {
            checkNotesProcess.running = true;
            readNotesProcess.running = true;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: 8
            DankIcon { name: "event"; size: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
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
            property var weekDays: ["Sha","Yek","Dos","Ses","Cha","Pan","Jom"]
            property int lineIndex: 0
            property bool isFirstWeek: true

            Process {
                id: jcalProcess
                command: ["sh", "-c", "jcal"]
                running: true
                onStarted: { popoutColumn.monthDays = []; popoutColumn.lineIndex = 0; popoutColumn.isFirstWeek = true; }
                stdout: SplitParser {
                    onRead: (line) => {
                        if (!line) return
                        let raw = line
                        let clean = raw.replace(/\x1b\[[0-9;]*m/g, "").replace(/\n$/, "")
                        if (popoutColumn.lineIndex === 0) popoutColumn.monthTitle = clean.trim()
                        else if (popoutColumn.lineIndex >= 2) {
                            let rowData = []
                            if (popoutColumn.isFirstWeek) {
                                let firstDigitIdx = clean.search(/\d/)
                                if (firstDigitIdx !== -1) {
                                    let padding = Math.floor(firstDigitIdx / 3)
                                    for (let i = 0; i < padding; i++) rowData.push({ day: "", isHoliday: false })
                                    popoutColumn.isFirstWeek = false
                                }
                            }
                            let parts = clean.trim().split(/\s+/)
                            for (let part of parts) {
                                if (!part) continue
                                let isHoliday = (new RegExp("\\x1b\\[[0-9;]*31m\\s*" + part)).test(raw)
                                rowData.push({ day: part, isHoliday: isHoliday })
                            }
                            popoutColumn.monthDays = popoutColumn.monthDays.concat(rowData)
                        }
                        popoutColumn.lineIndex++
                    }
                }
            }

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - 60 

                // --- صفحه تقویم ---
                Column {
                    id: viewCalendar
                    visible: !root.isDetailsView
                    anchors.fill: parent
                    spacing: 12

                    StyledText { text: popoutColumn.monthTitle; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; width: parent.width }

                    Row {
                        spacing: 0; width: 48 * 7; layoutDirection: Qt.RightToLeft; anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: popoutColumn.weekDays
                            delegate: StyledText { text: modelData; width: 48; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12; color: Theme.primary }
                        }
                    }

                    DankGridView {
                        width: 48 * 7; height: 48 * 6; cellWidth: 48; cellHeight: 48; model: popoutColumn.monthDays; layoutDirection: Qt.RightToLeft; anchors.horizontalCenter: parent.horizontalCenter
                        delegate: StyledRect {
                            width: 44; height: 44; radius: 22
                            property bool isEmpty: modelData.day === ""
                            property bool isToday: modelData.day === root.currentDay
                            property bool hasNote: root.daysWithNotes.split(',').includes(modelData.day)
                            color: isToday ? Theme.primary : "transparent"
                            StyledText {
                                anchors.centerIn: parent; text: modelData.day; visible: !isEmpty
                                color: isToday ? Theme.onPrimary : (modelData.isHoliday ? Theme.error : Theme.surfaceVariantText)
                            }
                            StyledRect {
                                visible: hasNote && !isEmpty; width: 4; height: 4; radius: 2; color: isToday ? Theme.onPrimary : Theme.primary
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 4; anchors.horizontalCenter: parent.horizontalCenter
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!isEmpty) {
                                        root.selectedDay = modelData.day;
                                        readNotesProcess.running = true;
                                        root.isDetailsView = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // --- صفحه جزئیات ---
                Column {
                    id: viewDetails
                    visible: root.isDetailsView
                    anchors.fill: parent
                    spacing: 15

                    // هدر
                    Item {
                        width: parent.width; height: 40
                        StyledRect {
                            width: 80; height: 32; color: Theme.surfaceVariant; radius: 6; anchors.left: parent.left
                            Row {
                                anchors.centerIn: parent; spacing: 4
                                DankIcon { name: "arrow_back"; size: 16; color: Theme.primary }
                                StyledText { text: "برگشت"; font.pixelSize: 12; color: Theme.primary }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.isDetailsView = false }
                        }
                        StyledText { 
                            text: "روز " + root.selectedDay; font.bold: true; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary 
                        }
                    }

                    // ورودی
                    Row {
                        width: parent.width; height: 40; spacing: 10
                        StyledRect {
                            width: 40; height: 40; color: Theme.primary; radius: 8
                            DankIcon { name: "add"; size: 20; color: Theme.onPrimary; anchors.centerIn: parent }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (reminderInput.text.trim() !== "") {
                                        saveProcess.reminderText = reminderInput.text.trim();
                                        saveProcess.running = true;
                                        reminderInput.text = "";
                                    }
                                }
                            }
                        }
                        StyledRect {
                            width: parent.width - 50; height: 40; color: Theme.surfaceVariant; radius: 8
                            TextInput {
                                id: reminderInput; anchors.fill: parent; anchors.margins: 8
                                color: Theme.surfaceVariantText; horizontalAlignment: TextInput.AlignRight; verticalAlignment: TextInput.AlignVCenter
                                onAccepted: {
                                    if (text.trim() !== "") {
                                        saveProcess.reminderText = text.trim();
                                        saveProcess.running = true;
                                        text = "";
                                    }
                                }
                            }
                        }
                    }

                    // لیست
                    Flickable {
                        width: parent.width; height: parent.height - 120; contentHeight: notesListCol.implicitHeight; clip: true
                        Column {
                            id: notesListCol; width: parent.width; spacing: 8
                            Repeater {
                                model: root.dayNotesList
                                delegate: StyledRect {
                                    width: parent.width; height: Math.max(40, txtNote.implicitHeight + 16); color: Theme.surfaceVariant; radius: 6
                                    StyledText {
                                        id: txtNote; text: modelData; anchors.fill: parent; anchors.margins: 10
                                        horizontalAlignment: Text.AlignRight; wrapMode: Text.WordWrap; color: Theme.surfaceVariantText
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 450
}
