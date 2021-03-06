import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import QgsQuick 0.1 as QgsQuick
import lc 1.0
import "."  // import InputStyle singleton

Item {

    property int activeProjectIndex: -1
    property string activeProjectPath: __projectsModel.data(__projectsModel.index(activeProjectIndex), ProjectModel.Path)
    property string activeProjectName: __projectsModel.data(__projectsModel.index(activeProjectIndex), ProjectModel.Name)
    property var busyIndicator

    property real rowHeight: InputStyle.rowHeightHeader * 1.2
    property bool showMergin: false

    function openPanel() {
        myProjectsBtn.clicked()
        projectsPanel.visible = true
    }

    function getStatusIcon(status) {
        if (status === "noVersion") return "download.svg"
        else if (status === "outOfDate") return "update.svg"
        else if (status === "upToDate") return "check.svg"
        else if (status === "modified") return "upload.svg"

        return "more_menu.svg"
    }


    Component.onCompleted: {
        // load model just after all components are prepared
        // otherwise GridView's delegate item is initialized invalidately
        grid.model = __projectsModel
        merginProjectsList.model = __merginProjectsModel
    }

    Connections {
        target: __merginApi
        onListProjectsFinished: {
            busyIndicator.running = false
        }
    }

    Connections {
      target: __merginApi
      onAuthRequested: {
        busyIndicator.running = false
        authPanel.visible = true
      }
    }

    Connections {
      target: __merginApi
      onAuthChanged: {
        if (__merginApi.hasAuthData()) {
            authPanel.close()
            merginProjectBtn.clicked()
        }
      }
    }

    id: projectsPanel
    visible: false
    focus: true

    Keys.onReleased: {
        if (!activeProjectPath) return

        if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
            event.accepted = true;
            projectsPanel.visible = false
        }
    }

    Keys.forwardTo: authPanel.visible ? authPanel : []

    // background
    Rectangle {
        width: parent.width
        height: parent.height
        color: InputStyle.clrPanelMain
    }

    BusyIndicator {
        id: busyIndicator
        width: parent.width/8
        height: width
        running: false
        visible: running
        anchors.centerIn: parent
    }

    PanelHeader {
        id: header
        height: InputStyle.rowHeightHeader
        width: parent.width
        color: InputStyle.clrPanelMain
        rowHeight: InputStyle.rowHeightHeader
        titleText: qsTr("Projects")

        onBack: projectsPanel.visible = false
        withBackButton: projectsPanel.activeProjectPath
    }

    ColumnLayout {
        id: contentLayout
        height: projectsPanel.height-header.height
        width: parent.width
        y: header.height
        spacing: 0

        TabBar {
            id: projectMenuButtons
            Layout.fillWidth: true
            spacing: 0
            implicitHeight: InputStyle.rowHeightHeader
            z: grid.z + 1

            background: Rectangle {
                color: InputStyle.panelBackgroundLight
            }

            PanelTabButton {
                id: myProjectsBtn
                height: projectMenuButtons.height
                text: qsTr("MY PROJECTS")
                horizontalAlignment: Text.AlignLeft

                onClicked: {showMergin = false; checked = true}
            }

            PanelTabButton {
                id: merginProjectBtn
                height: projectMenuButtons.height
                text: qsTr("ALL PROJECTS")
                horizontalAlignment: Text.AlignRight

                onClicked: {
                    busyIndicator.running = true
                    showMergin = true
                    __merginApi.listProjects()
                }
            }
        }

        ListView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: grid.width
            clip: true
            visible: !showMergin

            property int cellWidth: width
            property int cellHeight: projectsPanel.rowHeight
            property int borderWidth: 1

            delegate: delegateItem

            Label {
                anchors.fill: parent
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                visible: parent.count == 0
                text: qsTr("No projects found!")
                color: InputStyle.fontColor
                font.pixelSize: InputStyle.fontPixelSizeNormal
                font.bold: true
            }
        }

        ListView {
            id: merginProjectsList
            visible: showMergin
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: grid.width
            clip: true

            property int cellWidth: width
            property int cellHeight: projectsPanel.rowHeight
            property int borderWidth: 1

            delegate: delegateItemMergin
        }
    }

    Component {
        id: delegateItem
        ProjectDelegateItem {
            cellWidth: projectsPanel.width
            cellHeight: projectsPanel.rowHeight
            width: cellWidth
            height: cellHeight
            statusIconSource: "trash.svg"
            projectName: folderName
            disabled: !isValid // invalid project
            highlight: {
                if (disabled) return true
                return path === projectsPanel.activeProjectPath ? true : false
            }

            onItemClicked: {
                if (showMergin) return
                projectsPanel.activeProjectIndex = index
                __appSettings.defaultProject = path
                projectsPanel.visible = false
                projectsPanel.activeProjectIndexChanged()
            }

            onMenuClicked: {
                deleteDialog.relatedProjectIndex = index
                deleteDialog.open()
            }
        }
    }

    Component {
        id: delegateItemMergin
        ProjectDelegateItem {
            cellWidth: projectsPanel.width
            cellHeight: projectsPanel.rowHeight
            width: cellWidth
            height: cellHeight
            pending: pendingProject
            statusIconSource: getStatusIcon(status)

            onMenuClicked: {
                if (status === "upToDate") return

                __merginProjectsModel.setPending(index, true)

                if (status === "noVersion") {
                    __merginApi.downloadProject(name)
                } else if (status === "outOfDate") {
                    __merginApi.updateProject(name)
                } else if (status === "modified") {
                    __merginApi.uploadProject(name)
                }
            }

        }
    }
    AuthPanel {
        id: authPanel
        visible: false
        height: window.height
        width: parent.width
        onAuthFailed: myProjectsBtn.clicked()
    }

    MessageDialog {
      id: deleteDialog
      visible: false
      property int relatedProjectIndex

      title: qsTr( "Delete project" )
      text: qsTr( "Do you really want to delete project?" )
      icon: StandardIcon.Warning
      standardButtons: StandardButton.Ok | StandardButton.Cancel
      onAccepted: {
         __projectsModel.deleteProject(relatedProjectIndex)
        if (projectsPanel.activeProjectIndex === relatedProjectIndex) {
            __loader.load("")
            __loader.projectReloaded();
            projectsPanel.activeProjectIndex = -1
        }
        deleteDialog.relatedProjectIndex = -1
        visible = false
      }
      onRejected: {
        deleteDialog.relatedProjectIndex = -1
        visible = false
      }
    }
}
