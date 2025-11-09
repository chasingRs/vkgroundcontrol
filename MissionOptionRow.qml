// MissionOptionRow.qml
import QtQuick 2.15
import Controls 1.0
import ScreenTools 1.0

Row {
    property string labelText: ""
    property var options: []
    property int selectedIndex: 0
    property color mainColor: "green"
    signal selectionChanged(int index)

    width: parent.width
    spacing: 3

    Text {
        width: 160 * ScreenTools.scaleWidth
        text: labelText
        font.pixelSize: 25 * ScreenTools.scaleWidth
        height: 50 * ScreenTools.scaleWidth
        verticalAlignment: Text.AlignVCenter
        color: "white"
    }

    GroupButton {
        width: 400 * ScreenTools.scaleWidth
        height: 50 * ScreenTools.scaleWidth
        names: options
        selectedIndex: parent.selectedIndex
        mainColor: parent.mainColor
        fontSize: 20 * ScreenTools.scaleWidth
        backgroundColor: "Transparent"
        spacing: 2 * ScreenTools.scaleWidth

        onClicked: function(index) {
            parent.selectionChanged(index)
        }
    }
}
