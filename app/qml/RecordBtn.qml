import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QgsQuick 0.1 as QgsQuick

Item {
    id: recordBtnContainer
    height: width

    property int size: width / 2
    property int border: 10 * QgsQuick.Utils.dp
    property bool recording: false

    onRecordingChanged: {
        if (recording === false) {
            recBtn.borderWidth = recordBtnContainer.border
        }
    }

    function activated() {
        animation.start()
    }

    Rectangle {
        id: recBtn
        anchors.centerIn: parent
        property int borderWidth: recordBtnContainer.border
        width: size
        height: size
        color: recording ? "#fd5757" : "transparent"
        border.color: "white"
        border.width: borderWidth
        radius: width*0.5
        antialiasing: true

        SequentialAnimation {
            id: animation
            loops: Animation.Infinite
            running: recording
            NumberAnimation {
                target: recBtn
                property: "borderWidth"
                from: recordBtnContainer.border
                to: recordBtnContainer.border * 0.7
                duration: 300
            }
            NumberAnimation {
                target: recBtn
                property: "borderWidth"
                from: recordBtnContainer.border * 0.7
                to: recordBtnContainer.border
                duration: 300
            }
        }
    }

}
