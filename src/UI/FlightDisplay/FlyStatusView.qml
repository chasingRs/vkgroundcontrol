
/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import VKGroundControl
import Controls
import ScreenTools
import VKGroundControl.MissionModel 1.0
import VKGroundControl.ScanMissionModel 1.0
import VKGroundControl.AreaMissionModel 1.0
import VkSdkInstance 1.0

import "qrc:/qml/FlightDisplay" as Shared

Item {
      id: _root
      property bool showFlowView: false

      // 清洗界面弹出窗口
      Dialog {
            id: flowViewDialog
            modal: true
            closePolicy: Dialog.CloseOnEscape
            width: 1000 * ScreenTools.scaleWidth
            height: 700 * ScreenTools.scaleWidth
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            background: Rectangle {
                  color: "#101820"
                  border.color: "#2EE59D"
                  border.width: 2
                  radius: 15 * ScreenTools.scaleWidth
            }

            contentItem: Rectangle {
                  color: "transparent"
                  radius: 15 * ScreenTools.scaleWidth
                  clip: true

                  Loader {
                        id: flowLoader
                        anchors.fill: parent
                        active: true  // 始终保持激活，保留状态
                        source: "FlowView.qml"

                        Connections {
                              target: flowLoader.item
                              function onCloseRequested() {
                                    flowViewDialog.close()
                              }

                              function onLowWaterLevelAlert() {
                                    // 收到低液位警报信号，自动打开对话框
                                    console.log("📢 FlyStatusView 收到低液位警报，打开清洗界面对话框")
                                    flowViewDialog.open()
                              }
                        }
                  }
            }
      }

      //飞行页面右侧主界面按钮
      Column {
            visible: right_button_status === 0
            anchors {
                  verticalCenter: parent.verticalCenter
                  right: parent.right
                  rightMargin: 65 * ScreenTools.scaleWidth
            }
            spacing: 20 * ScreenTools.scaleWidth



            TextButton {
                  id:clean_btn
                  visible: Shared.AppState.appMode === 0
                      buttonText: qsTr("进入清洗界面")
                      height: button_height
                      width: 200 * ScreenTools.scaleWidth
                      onClicked: {
                          flowViewDialog.open()
                      }
                }

            TextButton {
                  buttonText: qsTr("规划任务")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        vkxuncha_msg.open()
                  }
            }
            TextButton {
                  buttonText: qsTr("执行任务")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        right_button_status = 3
                        VkSdkInstance.vehicleManager.activeVehicle.downloadMission(
                                          missionModel)
                  }
            }
            TextButton {
                  buttonText: qsTr("清空任务")
                  enabled: missionModel.itemCount > 0
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        if (missionModel.itemCount >= 0) {
                              missionModel.clear()
                        }
                  }
            }
      }

      //区域规划和带状规划按钮
      Column {
            visible: right_button_status === 1
            anchors {
                  verticalCenter: parent.verticalCenter
                  right: parent.right
                  rightMargin: 65 * ScreenTools.scaleWidth
            }
            spacing: 20 * ScreenTools.scaleWidth

            TextButton {
                  buttonText: qsTr("生成航线")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        if (mapControl.add_type === 3) {
                              missionModel.clear()
                              for (var i = 0; i < areaListModel.path().length; i++) {
                                    let latLng = areaListModel.path()[i]
                                    missionModel.addwppts(i + 1, latLng.longitude,
                                                          latLng.latitude,
                                                          areaSet.waypointAltitude,
                                                          areaSet.hoverTime,
                                                          areaSet.waypointSpeed, 1,
                                                          areaSet.waypointPhotoMode,
                                                          areaSet.photoModeValue, 0)
                              }
                              areaListModel.clear()
                              mapControl.add_type = 1
                        }
                        if (mapControl.add_type === 2) {
                              //missionModel.clear()
                              missionModel.clear()
                              for (var i = 0; i < scanListModel.path().length; i++) {
                                    let latLng = scanListModel.path()[i]
                                    missionModel.addwppts(i + 1, latLng.longitude,
                                                          latLng.latitude,
                                                          guanxian.waypointAltitude,
                                                          guanxian.hoverTime,
                                                          guanxian.waypointSpeed, 1,
                                                          guanxian.missionMode,
                                                          guanxian.photoModeValue, 0)
                              }
                              scanListModel.clear()
                              mapControl.add_type = 1
                        }
                        right_button_status = 2
                  }
            }
            TextButton {
                  buttonText: qsTr("返回")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        areaListModel.clear()
                        scanListModel.clear()
                        right_button_status = 0
                        mapControl.add_type = 0
                  }
            }
      }
      //上传航线按钮
      Column {
            visible: right_button_status === 2
            anchors {
                  verticalCenter: parent.verticalCenter
                  right: parent.right
                  rightMargin: 65 * ScreenTools.scaleWidth
            }
            spacing: 20 * ScreenTools.scaleWidth

            TextButton {
                  buttonText: qsTr("定位航点")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        // 判断是否成功定位
                        if (!VkSdkInstance.vehicleManager.activeVehicle) return
                        let activeVehicle = VkSdkInstance.vehicleManager.activeVehicle
                        let gpsFixType = activeVehicle.GNSS1.gpsInputFixType
                        if (gpsFixType > 1) {
                            let gpsLat = activeVehicle.GNSS1.gpsInputLatitude
                            let gpsLon = activeVehicle.GNSS1.gpsInputLongitude
                            mapControl.addWaypointByCoordinate(gpsLon, gpsLat)
                        } else {
                            console.warn(qsTr("GPS未定位,无法添加航点"))
                        }
                  }
            }

            TextButton {
                  buttonText: qsTr("上传航点")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        VkSdkInstance.vehicleManager.activeVehicle.uploadMissionModel(
                                          missionModel)
                        mapControl.add_type = 0
                        right_button_status = 3 //显示执行页面
                  }
            }

            TextButton {
                  buttonText: qsTr("返回")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        right_button_status = 0
                        missionModel.clear()
                        mapControl.add_type = 0
                  }
            }
      }
      //执行任务页面按钮
      Column {
            visible: right_button_status === 3
            anchors {
                  verticalCenter: parent.verticalCenter
                  right: parent.right
                  rightMargin: 65 * ScreenTools.scaleWidth
            }
            spacing: 20 * ScreenTools.scaleWidth

            TextButton {
                  buttonText: qsTr("开始航线")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        vk_start.open()
                  }
            }
            TextButton {
                  buttonText: qsTr("返航")
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        vkreturn.open()
                  }
            }
            TextButton {
                  buttonText: qsTr("返回")
                  //enabled:  customListModel.itemCount>0
                  height: button_height
                  width: 200 * ScreenTools.scaleWidth
                  onClicked: {
                        right_button_status = 0
                        mapControl.add_type = 0
                  }
            }
      }

      //舵机
      Row {
            anchors {
                top: parent.top
                right: parent.right
                rightMargin:  150 * ScreenTools.scaleWidth
                topMargin: 28 * ScreenTools.scaleWidth
            }
          Button{
                id:shuibeng_btn
                property int isopen : 0
              width:  70 * ScreenTools.scaleWidth
              height:  70 * ScreenTools.scaleWidth
              visible: !servoPopup.isVisible
              onClicked: {
                  // servoPopup.isVisible=!servoPopup.isVisible

                    if(isopen===0)
                    {
                          isopen = 1 ;
                          MyTcpClient.send_isopen_pump(0);
                    }
                    else
                    {
                          isopen = 0 ;
                        MyTcpClient.send_isopen_pump(1);
                    }
              }
              background:Rectangle{
                  anchors.fill: parent
                  color:  "#00000000"
                  Image{
                      anchors.fill: parent
                      source: shuibeng_btn.isopen ===1 ? "qrc:/qmlimages/icon/shuibeng_green.png" : "qrc:/qmlimages/icon/shuibeng_red.png"
                          /*"/qmlimages/icon/duoji.png"*/
                  }
              }
          }
      }

      //左侧航点属性框
      Row {
            z: 100
            height: parent.height
            width: ScreenTools.scaleWidth * 0.35 + 65 * ScreenTools.scaleWidth
            visible: mapControl.add_type !== 0
            Item {
                  width: mainWindow.width * 0.35
                  height: parent.height
                  visible: isleftsetbool
                  Rectangle {
                        width: mainWindow.width * 0.35
                        color: "#C0000000"
                        height: parent.height
                        visible: isleftsetbool

                        Item {
                              width: mainWindow.width * 0.35 - 4
                              height: parent.height

                              WaypointListPanel {
                                    id: missionPointPanel
                                    visible: mapControl.add_type === 1
                                    width: mainWindow.width * 0.35 - 4
                                    height: parent.height
                              }

                              VKAreaSet {
                                    id: areaSet
                                    visible: mapControl.add_type === 3
                                    width: mainWindow.width * 0.35 - 4
                                    height: parent.height
                              }

                              SurveyLineSettings {
                                    id: guanxian
                                    visible: mapControl.add_type === 2
                                    width: mainWindow.width * 0.35 - 4
                                    height: parent.height
                              }
                        }
                  }
            }
            Button {
                  //anchors.right:parent.right
                  //id:setbt
                  height: 100 * ScreenTools.scaleWidth
                  width: 50 * ScreenTools.scaleWidth
                  anchors.verticalCenter: parent.verticalCenter
                  Image {
                        id: setbt_img3
                        anchors.fill: parent
                        source: "/qmlimages/icon/right_arrow.png"
                  }
                  background: Rectangle {
                        color: "transparent"
                  }
                  MouseArea {
                        anchors.fill: parent
                        onClicked: {

                              isleftsetbool = !isleftsetbool
                              if (isleftsetbool) {
                                    setbt_img3.source = "/qmlimages/icon/left_arrow.png"
                              } else {
                                    setbt_img3.source = "/qmlimages/icon/right_arrow.png"
                              }
                        }
                  }
            }
      }

      //飞行页面设置页面
      FlyViewRightSetWindow {
            id: flyviewrightset
            height: parent.height
            z: 100
      }
      FlyViewMsgPanel {
            id: yibiao
            width: 800 * ScreenTools.scaleWidth
            height: 200 * ScreenTools.scaleWidth
            anchors.bottomMargin: 10 * ScreenTools.scaleWidth
            anchors.bottom: parent.bottom
            anchors.leftMargin: 400 * ScreenTools.scaleWidth
            anchors.left: parent.left
            //visible: showidwindow===1
            //visible:video_visible===false&showidwindow===1&( mainWindow.application_setting_id===3112 || mainWindow.application_setting_id===41 || mainWindow.application_setting_id==10|| mainWindow.application_setting_id===11|| mainWindow.application_setting_id==12|| mainWindow.application_setting_id==20|| mainWindow.application_setting_id==21||  mainWindow.application_setting_id==112|| mainWindow.application_setting_id==122|| mainWindow.application_setting_id==212|| mainWindow.application_setting_id==222)
      }

      MissionTypeSelector {
            width: parent.width / 2
            id: vkxuncha_msg
            anchors.centerIn: parent
            onMissionTypeSelected: function (missionType) {
                  if (missionType === 1) {

                        mapControl.add_type = 1
                        right_button_status = 2
                  }
                  if (missionType === 2) {

                        mapControl.add_type = 2
                        right_button_status = 1
                  }
                  if (missionType === 3) {

                        mapControl.add_type = 3
                        right_button_status = 1
                  }
            }
      }

      WaypointSettingsDialog {
            id: xunchapoint
            width: 800 * sw
            anchors.centerIn: parent
      }

      VKStartMission {
            width: 800 * ScreenTools.scaleWidth
            id: vk_start
            anchors.centerIn: parent
      }

      VKReturn {
            width: 800 * ScreenTools.scaleWidth
            id: vkreturn
            anchors.centerIn: parent
      }

      VKServoStatusPopup {
            id: servoPopup
            visible: servoPopup.isVisible
            anchors {
                top:parent.top
                right: parent.right
                rightMargin:  80 * ScreenTools.scaleWidth
            }
      }

}
