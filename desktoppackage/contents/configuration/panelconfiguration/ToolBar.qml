/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.configuration 2.0
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: root
    // Do not use Layout's implicitWidth/implicitHeight as they are updated too late (BUG 443294)
    implicitWidth: Math.max(addWidgetsButton.implicitWidth, addSpacerButton.implicitWidth, settingsButton.implicitWidth, spinBoxLabel.implicitWidth, spinBox.implicitWidth) + PlasmaCore.Units.smallSpacing * 2
    implicitHeight: Math.max(addWidgetsButton.implicitHeight, addSpacerButton.implicitHeight, settingsButton.implicitHeight, spinBoxLabel.implicitHeight, spinBox.implicitHeight) + PlasmaCore.Units.smallSpacing * 5

    readonly property string addWidgetsButtonText: i18nd("plasma_shell_org.kde.plasma.desktop", "Add Widgets…")
    readonly property string addSpacerButtonText: i18nd("plasma_shell_org.kde.plasma.desktop", "Add Spacer")
    readonly property string settingsButtonText: i18nd("plasma_shell_org.kde.plasma.desktop", "More Options…")

    KQuickControlsAddons.MouseEventListener {
        id: mel
        cursorShape: Qt.SizeAllCursor
        anchors.fill: parent
        property int lastX
        property int lastY
        property int startMouseX
        property int startMouseY
        onPressed: {
            dialogRoot.closeContextMenu();
            lastX = mouse.screenX
            lastY = mouse.screenY
            startMouseX = mouse.x
            startMouseY = mouse.y
            tooltip.visible = true
        }
        onPositionChanged: {
            panel.screenToFollow = mouse.screen;

            var newLocation = panel.location;
            //If the mouse is in an internal rectangle, do nothing
            if ((mouse.screenX < panel.screenGeometry.x + panel.screenGeometry.width/3 ||
                mouse.screenX > panel.screenGeometry.x + panel.screenGeometry.width/3*2) ||
                (mouse.screenY < panel.screenGeometry.y + panel.screenGeometry.height/3 ||
                mouse.screenY > panel.screenGeometry.y + panel.screenGeometry.height/3*2))
            {
                var screenAspect = panel.screenGeometry.height / panel.screenGeometry.width;

                if (mouse.screenY < panel.screenGeometry.y+(mouse.screenX-panel.screenGeometry.x)*screenAspect) {
                    if (mouse.screenY < panel.screenGeometry.y + panel.screenGeometry.height-(mouse.screenX-panel.screenGeometry.x)*screenAspect) {
                        newLocation = PlasmaCore.Types.TopEdge;
                    } else {
                        newLocation = PlasmaCore.Types.RightEdge;
                    }

                } else {
                    if (mouse.screenY < panel.screenGeometry.y + panel.screenGeometry.height-(mouse.screenX-panel.screenGeometry.x)*screenAspect) {
                        newLocation = PlasmaCore.Types.LeftEdge;
                    } else {
                        newLocation = PlasmaCore.Types.BottomEdge;
                    }
                }
            }
            panel.location = newLocation

            switch (newLocation) {
                case PlasmaCore.Types.TopEdge:
                    var y = Math.max(mouse.screenY - mapToItem(dialogRoot, 0, startMouseY).y, panel.height);
                    configDialog.y = y;
                    panel.distance = Math.max(y - panel.height - panel.screenToFollow.geometry.y, 0);
                    break
                case PlasmaCore.Types.LeftEdge:
                    var x = Math.max(mouse.screenX - mapToItem(dialogRoot, startMouseX, 0).x, panel.width);
                    configDialog.x = x;
                    panel.distance = Math.max(x - panel.width - panel.screenToFollow.geometry.x, 0);
                    break;
                case PlasmaCore.Types.RightEdge:
                    var x = Math.min(mouse.screenX - mapToItem(dialogRoot, startMouseX, 0).x, mouse.screen.geometry.x + mouse.screen.size.width - panel.width - configDialog.width);
                    configDialog.x = x;
                    panel.distance = Math.max(mouse.screen.size.width - (x - mouse.screen.geometry.x) - panel.width - configDialog.width, 0);
                    break;
                case PlasmaCore.Types.BottomEdge:
                default:
                    var y = Math.min(mouse.screenY - mapToItem(dialogRoot, 0, startMouseY).y, mouse.screen.geometry.y + mouse.screen.size.height - panel.height - configDialog.height);
                    configDialog.y = y;
                    panel.distance = Math.max(mouse.screen.size.height - (y - mouse.screen.geometry.y) - panel.height - configDialog.height, 0);
            }

            lastX = mouse.screenX
            lastY = mouse.screenY
        }
        onReleased: {
            panel.distance = 0
            panelResetAnimation.running = true
        }
    }

    QQC2.Action {
        shortcut: "Escape"
        onTriggered: {
            // avoid leaving the panel in an inconsistent state when escaping while dragging it
            if (mel.pressed) {
                return
            }

            if (contextMenuLoader.opened) {
                contextMenuLoader.close()
            } else {
                configDialog.close()
            }
        }
    }

    GridLayout {
        id: buttonsLayout_1
        rows: 1
        columns: 1
        flow: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? GridLayout.TopToBottom : GridLayout.LeftToRight

        anchors.margins: rowSpacing
        anchors.topMargin: plasmoid.formFactor === PlasmaCore.Types.Vertical ? rowSpacing + closeButton.height : rowSpacing

        rowSpacing: PlasmaCore.Units.smallSpacing
        columnSpacing: PlasmaCore.Units.smallSpacing

        PlasmaComponents3.Button {
            id: addWidgetsButton
            text: root.addWidgetsButtonText
            icon.name: "list-add"
            Layout.fillWidth: true
            onClicked: {
                configDialog.close();
                configDialog.showAddWidgetDialog();
            }
        }

        PlasmaComponents3.Button {
            id: addSpacerButton
            text: root.addSpacerButtonText
            icon.name: "distribute-horizontal-x"
            Layout.fillWidth: true
            onClicked: {
                configDialog.addPanelSpacer();
            }
        }
    }

    GridLayout {
        id: row
        columns: dialogRoot.vertical ? 1 : 4
        rows: dialogRoot.vertical ? 4 : 1
        anchors.centerIn: parent

        rowSpacing: PlasmaCore.Units.smallSpacing
        columnSpacing: PlasmaCore.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            horizontalAlignment: Qt.AlignHCenter
            text: i18ndc("plasma_shell_org.kde.plasma.desktop", "Minimize the length of this string as much as possible", "Drag to move")
        }
        Item {
            Layout.preferredWidth: dialogRoot.vertical ? 0 : PlasmaCore.Units.gridUnit * 8
            Layout.preferredHeight: dialogRoot.vertical ? PlasmaCore.Units.gridUnit * 8 : 0
        }
        PlasmaComponents3.Label {
            id: spinBoxLabel
            Layout.fillWidth: true
            wrapMode: Text.Wrap

            text: panel.location === PlasmaCore.Types.LeftEdge || panel.location === PlasmaCore.Types.RightEdge ? i18nd("plasma_shell_org.kde.plasma.desktop", "Panel width:") : i18nd("plasma_shell_org.kde.plasma.desktop", "Panel height:")
        }
        PlasmaComponents3.SpinBox {
            id: spinBox
            Layout.fillWidth: true

            editable: true
            focus: !Kirigami.InputMethod.willShowOnActive

            from: 20 // below this size, the panel is mostly unusable
            to: PlasmaCore.Types.LeftEdge || panel.location === PlasmaCore.Types.RightEdge ? panel.screenToFollow.geometry.width / 2 : panel.screenToFollow.geometry.height / 2

            stepSize: 2

            value: panel.thickness
            onValueModified: {
                panel.thickness = value
                // Adjust the position of the config bar too
                switch (panel.location) {
                    case PlasmaCore.Types.TopEdge:
                        configDialog.y = Qt.binding(function() { return panel.y + panel.thickness });
                        break;
                    case PlasmaCore.Types.LeftEdge:
                        configDialog.x = Qt.binding(function() { return panel.x + panel.thickness });
                        break;
                    case PlasmaCore.Types.RightEdge:
                        configDialog.x = Qt.binding(function() { return panel.x - configDialog.width });
                        break;
                    case PlasmaCore.Types.BottomEdge:
                    default:
                        configDialog.y = Qt.binding(function() { return panel.y - configDialog.height });
                        break;
                }
            }
            DragHandler {
                property int magnitude: PlasmaCore.Units.gridUnit
                target: null
                xAxis.enabled: panel.location == PlasmaCore.Types.LeftEdge || panel.location == PlasmaCore.Types.RightEdge
                yAxis.enabled: panel.location == PlasmaCore.Types.TopEdge || panel.location == PlasmaCore.Types.BottomEdge
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                onTranslationChanged: {
                    var distance
                    switch (panel.location) {
                    case PlasmaCore.Types.TopEdge:
                        distance = translation.y
                        break;
                    case PlasmaCore.Types.LeftEdge:
                        distance = translation.x
                        break;
                    case PlasmaCore.Types.RightEdge:
                        distance = -translation.x
                        break;
                    case PlasmaCore.Types.BottomEdge:
                    default:
                        distance = -translation.y
                        break;
                    }
                    parent.value = parent.value + (Math.floor(distance / magnitude) * parent.stepSize)
                    parent.valueModified()
                }
            }
        }
    }

    PlasmaComponents3.Label {
        id: placeHolder
        visible: false
        text: addWidgetsButtonText + addSpacerButtonText + settingsButtonText
    }

    Connections {
        target: configDialog
        function onVisibleChanged() {
            if (!configDialog.visible) {
                settingsButton.checked = false
            }
        }
    }

    GridLayout {
        id: buttonsLayout_2
        rows: 1
        columns: 1
        flow: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? GridLayout.TopToBottom : GridLayout.LeftToRight

        anchors.margins: rowSpacing

        rowSpacing: PlasmaCore.Units.smallSpacing
        columnSpacing: PlasmaCore.Units.smallSpacing

        PlasmaComponents3.Button {
            id: settingsButton
            text: root.settingsButtonText
            icon.name: "configure"
            Layout.fillWidth: true
            checkable: true
            onCheckedChanged: {
                if (checked) {
                    contextMenuLoader.open()
                } else {
                    contextMenuLoader.close()
                }
            }
        }

        PlasmaComponents3.ToolButton {
            id: closeButton
            parent: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? buttonsLayout_2 : root
            anchors.right: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? undefined : parent.right
            icon.name: "window-close"
            onClicked: {
                configDialog.close()
            }
            PlasmaComponents3.ToolTip {
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "Close")
            }
        }

        Loader {
            id: contextMenuLoader
            property bool opened: item && item.visible
            onOpenedChanged: settingsButton.checked = opened
            source: "MoreSettingsMenu.qml"
            active: false

            function open() {
                active = true
                item.visible = true
            }
            function close() {
                if (item) {
                    item.visible = false
                }
            }
        }

    }
//BEGIN States
    states: [
        State {
            name: "TopEdge"
            PropertyChanges {
                target: root
                height: root.implicitHeight
            }
            AnchorChanges {
                target: root
                anchors {
                    top: undefined
                    bottom: root.parent.bottom
                    left: root.parent.left
                    right: root.parent.right
                }
            }
            AnchorChanges {
                target: buttonsLayout_1
                anchors {
                    verticalCenter: root.verticalCenter
                    top: undefined
                    bottom: undefined
                    left: root.left
                    right: undefined
                }
            }
            AnchorChanges {
                target: buttonsLayout_2
                anchors {
                    verticalCenter: root.verticalCenter
                    top: undefined
                    bottom: undefined
                    left: undefined
                    right: root.right
                }
            }
            PropertyChanges {
                target: buttonsLayout_1
                width: buttonsLayout_1.implicitWidth
            }
            PropertyChanges {
                target: buttonsLayout_2
                width: buttonsLayout_2.implicitWidth
            }
        },
        State {
            name: "BottomEdge"
            PropertyChanges {
                target: root
                height: root.implicitHeight
            }
            AnchorChanges {
                target: root
                anchors {
                    top: root.parent.top
                    bottom: undefined
                    left: root.parent.left
                    right: root.parent.right
                }
            }
            AnchorChanges {
                target: buttonsLayout_1
                anchors {
                    verticalCenter: root.verticalCenter
                    top: undefined
                    bottom: undefined
                    left: root.left
                    right: undefined
                }
            }
            AnchorChanges {
                target: buttonsLayout_2
                anchors {
                    verticalCenter: root.verticalCenter
                    top: undefined
                    bottom: undefined
                    left: undefined
                    right: root.right
                }
            }
            PropertyChanges {
                target: buttonsLayout_1
                width: buttonsLayout_1.implicitWidth
            }
            PropertyChanges {
                target: buttonsLayout_2
                width: buttonsLayout_2.implicitWidth
            }
        },
        State {
            name: "LeftEdge"
            PropertyChanges {
                target: root
                width: root.implicitWidth
            }
            PropertyChanges {
                target: buttonsLayout_2
                implicitHeight: -1 // Prevent the panel from being too narrow
            }
            AnchorChanges {
                target: root
                anchors {
                    top: root.parent.top
                    bottom: root.parent.bottom
                    left: undefined
                    right: root.parent.right
                }
            }
            AnchorChanges {
                target: buttonsLayout_1
                anchors {
                    verticalCenter: undefined
                    top: root.top
                    bottom: undefined
                    left: root.left
                    right: root.right
                }
            }
            AnchorChanges {
                target: buttonsLayout_2
                anchors {
                    verticalCenter: undefined
                    top: undefined
                    bottom: root.bottom
                    left: root.left
                    right: root.right
                }
            }
        },
        State {
            name: "RightEdge"
            PropertyChanges {
                target: root
                width: root.implicitWidth
            }
            PropertyChanges {
                target: buttonsLayout_2
                implicitHeight: -1 // Prevent the panel from being too narrow
            }
            AnchorChanges {
                target: root
                anchors {
                    top: root.parent.top
                    bottom: root.parent.bottom
                    left: root.parent.left
                    right: undefined
                }
            }
            AnchorChanges {
                target: buttonsLayout_1
                anchors {
                    verticalCenter: undefined
                    top: root.top
                    bottom: undefined
                    left: root.left
                    right: root.right
                }
            }
            AnchorChanges {
                target: buttonsLayout_2
                anchors {
                    verticalCenter: undefined
                    top: undefined
                    bottom: root.bottom
                    left: root.left
                    right: root.right
                }
            }
        }
    ]
//END States
}
