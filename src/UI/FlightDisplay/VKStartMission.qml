// import QtQuick 2.15
// import QtQuick.Controls 2.15
// import QGroundControl 1.0
// import Controls 1.0
// import ScreenTools
// import VkSdkInstance

// Popup {
//     id: root
//     width: popupWidth
//     height: mainColumn.height
//     focus: true
//     closePolicy: Popup.NoAutoClose
    
//     // Properties with camelCase naming
//     property real buttonFontSize: 30 * ScreenTools.scaleWidth
//     property int popupWidth: 600 * ScreenTools.scaleWidth
//     property int popupHeight: 720 * ScreenTools.scaleWidth
//     property color backgroundColor: ScreenTools.titleColor
//     property int returnMode: 0 // 返航方式
//     property int isclean: 0
//     property int missionType: 1 // 航线方式 正序航线和逆序航线
//     property int climbMode: VkSdkInstance.vehicleManager.activeVehicle ?
//                            parseInt(VkSdkInstance.vehicleManager.activeVehicle.parameters["WP_FP_ALT_MODE"]) : 0
//     property var activeVehicle: VkSdkInstance.vehicleManager.activeVehicle
//     property bool showFlowView: false

//     // Popup entrance animation
//     enter: Transition {
//         NumberAnimation {
//             property: "opacity"
//             from: 0.0
//             to: 1.0
//         }
//     }

//     // Background styling
//     background: Rectangle {
//         anchors.fill: parent
//         radius: 15
//         color: "transparent"
        
//         Rectangle {
//             anchors.fill: parent
//             radius: 15
//             color: "#A0000000"
//         }
//     }

//     // Main content
//     Column {
//         id: mainColumn
//         width: parent.width
//         spacing: 30 * ScreenTools.scaleWidth

//         // Top spacing
//         Item {
//             width: parent.width
//             height: 30 * ScreenTools.scaleWidth
//         }

//         // Mission configuration section
//         Item {
//             width: parent.width
//             height: 400 * ScreenTools.scaleWidth

//             Column {
//                 width: 640 * ScreenTools.scaleWidth
//                 anchors.centerIn: parent
//                 height: parent.height
//                 spacing: 30 * ScreenTools.scaleWidth

//                 // Mission sequence selection
//                 MissionOptionRow {
//                     labelText: qsTr("航线方式")
//                     options: [qsTr("正序航线"), qsTr("逆序航线")]
//                     selectedIndex: missionType - 1
//                     onSelectionChanged: function(index) {
//                         missionType = index + 1
//                     }
//                 }

//                 // Climb mode selection
//                 MissionOptionRow {
//                     labelText: qsTr("去航点方式")
//                     options: [qsTr("垂直爬高"), qsTr("斜线爬高")]
//                     selectedIndex: climbMode
//                     onSelectionChanged: function(index) {
//                         climbMode = index
//                         if (activeVehicle) {
//                             activeVehicle.setParam("WP_FP_ALT_MODE", index)
//                         }
//                     }
//                 }

//                 // Mission completion action selection
//                 MissionOptionRow {
//                     // visible: isclean =0
//                     labelText: qsTr("完成航线动作")
//                     options: [qsTr("悬停"), qsTr("返航"), qsTr("降落")]
//                     selectedIndex: returnMode
//                     onSelectionChanged: function(index) {
//                         returnMode = index
//                     }
//                 }
//                 //清洗界面按钮
//                 // MissionOptionRow {
//                 //     visible: isclean =1
//                 //     labelText: qsTr("清洗开关")
//                 //     options: [qsTr("开始清洗"), qsTr("暂停清洗")]
//                 //     selectedIndex: returnMode
//                 //     onSelectionChanged: function(index) {
//                 //         returnMode = index
//                 //     }
//                 // }

//                 MissionOptionRow {
//                     visible: isclean =1
//                     labelText: qsTr("清洗模式")
//                     options: [qsTr("手动清洗"), qsTr("自动清洗")]
//                     selectedIndex: returnMode
//                     onSelectionChanged: function(index) {
//                         //returnMode = index
//                     }
//                 }

//                 TextButton {
//                       buttonText: qsTr("进入清洗界面")
//                       height: button_height
//                       width: 200 * ScreenTools.scaleWidth
//                       onClicked: {
//                           showFlowView = true
//                       }
//                 }

//                 // Loader {
//                 //        id: flowLoader
//                 //        anchors.fill: parent
//                 //        active: showFlowView          // 按钮控制加载
//                 //        source: "FlowView.qml"
//                 //    }

//                 // MissionOptionRow {
//                 //     visible: isclean =1
//                 //     labelText: qsTr("完成航线动作")
//                 //     options: [qsTr("清洗"),qsTr("悬停"), qsTr("返航"), qsTr("降落")]
//                 //     selectedIndex: returnMode
//                 //     onSelectionChanged: function(index) {
//                 //         returnMode = index
//                 //     }
//                 // }
//             }
//             // Loader {
//             //        id: flowLoader
//             //        anchors.fill: parent
//             //        active: showFlowView          // 按钮控制加载
//             //        source: "FlowView.qml"
//             //    }

//             Connections {
//                 target: flowLoader.item
//                 function onCloseRequested() {
//                     showFlowView = false
//                 }
//             }
//         }

//         // Description text
//         Item {
//             width: parent.width
//             height: 30 * ScreenTools.scaleWidth
            
//             Text {
//                 anchors.centerIn: parent
//                 color: "white"
//                 font.pixelSize: 20 * ScreenTools.scaleWidth
//                 text: getDescriptionText()
//                 horizontalAlignment: Text.AlignHCenter
//                 verticalAlignment: Text.AlignVCenter
//             }
//         }

//         // Execute slider
//         Item {
//             width: parent.width
//             height: 80 * ScreenTools.scaleWidth
            
//             SliderSwitch {
//                 id: executeSlider
//                 width: 600 * ScreenTools.scaleWidth
//                 height: 80 * ScreenTools.scaleWidth
//                 fontsize: 30 * ScreenTools.scaleWidth
//                 anchors.horizontalCenter: parent.horizontalCenter
//                 labeltext: qsTr("执行")
                
//                 onAccept: {
//                     executeMission()
//                     root.close()
//                 }
                
//                 onCancel: {
//                     root.close()
//                 }
//             }
//         }

//         Item {
//             width: parent.width
//             height: 30 * ScreenTools.scaleWidth
//         }
//     }
//     Loader {
//            id: flowLoader
//            anchors.fill: parent
//            active: showFlowView          // 按钮控制加载
//            source: "FlowView.qml"
//        }

//     // Helper functions
//     function getDescriptionText() {
//         switch(missionType) {
//             case 1:
//                 return qsTr("飞机从1点进入航线按照正序航线执行任务")
//             case 2:
//                 return qsTr("飞机从最后1点进入航线按照逆序航线执行,逆序航线不执行航点动作")
//             case 3:
//                 return qsTr("飞机按照航线返航到A点上方，然后垂直降落到A点位置")
//             default:
//                 return ""
//         }
//     }

//     function executeMission() {
//         if (missionType === 1) {
//             activeVehicle.startMission("NaN", 0, returnMode)
//         }
//         if (missionType === 2) {
//             activeVehicle.startMission("NaN", 3, returnMode) // 逆序执行航线 最后一点悬停
//         }
//     }

//     // Reusable Mission Option Row Compo
//     component MissionOptionRow: Row {
//         property string labelText: ""
//         property var options: []
//         property int selectedIndex: 0
//         signal selectionChanged(int index)

//         width: parent.width
//         spacing: 3

//         Text {
//             width: 240 * ScreenTools.scaleWidth
//             text: labelText
//             font.pixelSize: 25 * ScreenTools.scaleWidth
//             height: 50 * ScreenTools.scaleWidth
//             verticalAlignment: Text.AlignVCenter
//             color: "white"
//         }

//         GroupButton {
//             width: 400 * ScreenTools.scaleWidth
//             height: 50 * ScreenTools.scaleWidth
//             names: options
//             selectedIndex: parent.selectedIndex
//             mainColor: root.backgroundColor
//             fontSize: 20 * ScreenTools.scaleWidth
//             backgroundColor: "Transparent"
//             spacing: 2 * ScreenTools.scaleWidth
            
//             onClicked: function(index) {
//                 parent.selectionChanged(index)
//             }
//         }
//     }
// }


import QtQuick 2.15
import QtQuick.Controls 2.15
import QGroundControl 1.0
import Controls 1.0
import ScreenTools
import VkSdkInstance

import "qrc:/qml/FlightDisplay" as Shared

Popup {
    id: root
    width: popupWidth
    height: mainColumn.height
    focus: true
    closePolicy: Popup.NoAutoClose

    // Properties with camelCase naming
    property real buttonFontSize: 30 * ScreenTools.scaleWidth
    property int popupWidth: 600 * ScreenTools.scaleWidth
    property int popupHeight: 720 * ScreenTools.scaleWidth
    property color backgroundColor: ScreenTools.titleColor
    property int returnMode: 0 // 返航方式
    property int isclean: 0
    property int missionType: 1 // 航线方式 正序航线和逆序航线
    property int climbMode: VkSdkInstance.vehicleManager.activeVehicle ?
                           parseInt(VkSdkInstance.vehicleManager.activeVehicle.parameters["WP_FP_ALT_MODE"]) : 0
    property var activeVehicle: VkSdkInstance.vehicleManager.activeVehicle

    // Popup entrance animation
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
        }
    }

    // Background styling
    background: Rectangle {
        anchors.fill: parent
        radius: 15
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 15
            color: "#A0000000"
        }
    }

    // Main content
    Column {
        id: mainColumn
        width: parent.width
        spacing: 30 * ScreenTools.scaleWidth

        // Top spacing
        Item {
            width: parent.width
            height: 30 * ScreenTools.scaleWidth
        }

        // Mission configuration section
        Item {
            width: parent.width
            height: 400 * ScreenTools.scaleWidth

            Column {
                width: 640 * ScreenTools.scaleWidth
                anchors.centerIn: parent
                height: parent.height
                spacing: 30 * ScreenTools.scaleWidth

                // Mission sequence selection
                MissionOptionRow {
                    labelText: qsTr("航线方式")
                    options: [qsTr("正序航线"), qsTr("逆序航线")]
                    selectedIndex: missionType - 1
                    onSelectionChanged: function(index) {
                        missionType = index + 1
                    }
                }

                // Climb mode selection
                MissionOptionRow {
                    labelText: qsTr("去航点方式")
                    options: [qsTr("垂直爬高"), qsTr("斜线爬高")]
                    selectedIndex: climbMode
                    onSelectionChanged: function(index) {
                        climbMode = index
                        if (activeVehicle) {
                            activeVehicle.setParam("WP_FP_ALT_MODE", index)
                        }
                    }
                }

                // Mission completion action selection
                MissionOptionRow {
                    // visible: isclean =0
                    labelText: qsTr("完成航线动作")
                    options: [qsTr("悬停"), qsTr("返航"), qsTr("降落")]
                    selectedIndex: returnMode
                    onSelectionChanged: function(index) {
                        returnMode = index
                    }
                }
                //清洗界面按钮
                // MissionOptionRow {
                //     visible: isclean =1
                //     labelText: qsTr("清洗开关")
                //     options: [qsTr("开始清洗"), qsTr("暂停清洗")]
                //     selectedIndex: returnMode
                //     onSelectionChanged: function(index) {
                //         returnMode = index
                //     }
                // }

                MissionOptionRow {
                    visible: isclean === 1;
                    labelText: qsTr("清洗模式")
                    options: [qsTr("手动清洗"), qsTr("自动清洗")]
                    selectedIndex: index0
                    onSelectionChanged: function(index) {
                        //returnMode = index
                    }
                }


                // Loader {
                //        id: flowLoader
                //        anchors.fill: parent
                //        active: showFlowView          // 按钮控制加载
                //        source: "FlowView.qml"
                //    }

                // MissionOptionRow {
                //     visible: isclean =1
                //     labelText: qsTr("完成航线动作")
                //     options: [qsTr("清洗"),qsTr("悬停"), qsTr("返航"), qsTr("降落")]
                //     selectedIndex: returnMode
                //     onSelectionChanged: function(index) {
                //         returnMode = index
                //     }
                // }
            }
            // Loader {
            //        id: flowLoader
            //        anchors.fill: parent
            //        active: showFlowView          // 按钮控制加载
            //        source: "FlowView.qml"
            //    }


        }

        // Description text
        Item {
            width: parent.width
            height: 30 * ScreenTools.scaleWidth

            Text {
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 20 * ScreenTools.scaleWidth
                text: getDescriptionText()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Execute slider
        Item {
            width: parent.width
            height: 80 * ScreenTools.scaleWidth

            SliderSwitch {
                id: executeSlider
                width: 600 * ScreenTools.scaleWidth
                height: 80 * ScreenTools.scaleWidth
                fontsize: 30 * ScreenTools.scaleWidth
                anchors.horizontalCenter: parent.horizontalCenter
                labeltext: qsTr("执行")

                onAccept: {
                    executeMission()
                    root.close()
                }

                onCancel: {
                    root.close()
                }
            }
        }

        Item {
            width: parent.width
            height: 30 * ScreenTools.scaleWidth
        }
    }

    // Helper functions
    function getDescriptionText() {
        switch(missionType) {
            case 1:
                return qsTr("飞机从1点进入航线按照正序航线执行任务")
            case 2:
                return qsTr("飞机从最后1点进入航线按照逆序航线执行,逆序航线不执行航点动作")
            case 3:
                return qsTr("飞机按照航线返航到A点上方，然后垂直降落到A点位置")
            default:
                return ""
        }
    }

    function executeMission() {
        if (missionType === 1) {
            activeVehicle.startMission("NaN", 0, returnMode)
        }
        if (missionType === 2) {
            activeVehicle.startMission("NaN", 3, returnMode) // 逆序执行航线 最后一点悬停
        }
    }

    // Reusable Mission Option Row Component
    component MissionOptionRow: Row {
        property string labelText: ""
        property var options: []
        property int selectedIndex: 0
        signal selectionChanged(int index)

        width: parent.width
        spacing: 3

        Text {
            width: 240 * ScreenTools.scaleWidth
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
            mainColor: root.backgroundColor
            fontSize: 20 * ScreenTools.scaleWidth
            backgroundColor: "Transparent"
            spacing: 2 * ScreenTools.scaleWidth

            onClicked: function(index) {
                parent.selectionChanged(index)
            }
        }
    }
}
