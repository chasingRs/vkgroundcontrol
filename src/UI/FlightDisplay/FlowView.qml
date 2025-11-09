import QtQuick 2.15
import QtQuick.Controls 2.15
import Controls 1.0
import FlightDisplay 1.0
import VkSdkInstance
import ScreenTools 1.0

Rectangle {
    id: root
    // width: 480
    // height: 300
    // width: ScreenTools.screenWidth
    // height: ScreenTools.screenHeight
    anchors.fill: parent
    color: "#101820"
    signal closeRequested()

    // 使用新的连接状态属性
    property int isopen_pump: 1
    property int init_pump : 0
    property bool isConnected: MyTcpClient ? MyTcpClient.connected : false
    property bool isConnecting: MyTcpClient ? MyTcpClient.connecting : false
    property string connectionStatus: {
        if (!MyTcpClient) return "未初始化"
        if (isConnected) return "已连接"
        if (isConnecting) return "连接中..."
        return "未连接"
    }
    property color statusColor: {
        if (!MyTcpClient) return "#FFA726"
        if (isConnected) return "#2EE59D"
        if (isConnecting) return "#FFA726"
        return "#FF6B6B"
    }

    // 添加本地属性来存储值
    property double currentFlowRate: 0.0
    property double currentTotalVolume: 0.0

    // 整体布局：垂直分三部分
    Column {
        anchors.centerIn: parent
        spacing: 18 * ScreenTools.scaleWidth
        width: parent.width * 0.9
        height: parent.height * 0.9

        // 返回按钮
        Rectangle {
            width: parent.width * 0.42
            height: parent.height * 0.1
            radius: 6 * ScreenTools.scaleWidth
            color: "#15232D"
            border.color: "#2A3B4A"
            border.width: 0

            Button {
                id: rtn_btn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: parent.width * 0.05
                width: parent.width * 0.4
                height: parent.height * 0.8
                text: "返回"
                font.pixelSize: 16 * ScreenTools.scaleWidth
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#2EE59D"
                    border.color: "#2EE59D"
                }
                onClicked: closeRequested()
            }

            Button {
                anchors.left: rtn_btn.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: parent.width * 0.1
                width: parent.width * 0.4
                height: parent.height * 0.8
                text: "初始化"
                font.pixelSize: 16 * ScreenTools.scaleWidth
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#2EE59D"
                    border.color: "#2EE59D"
                }
                onClicked: {
                    init_pump = 1;
                    MyTcpClient.send_init_pump(init_pump);
                    // init_pump=0;
                    // MyTcpClient.send_init_pump(init_pump);
                    }
            }
        }

        // ================== 标题 ==================
        Text {
            id: header
            text: "💧 水泵实时监控"
             height: parent.height * 0.1
            color: "#00E5FF"
            font.bold: true
            font.pixelSize: 32 * ScreenTools.scaleWidth
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // ================== 连接状态显示 ==================
        // Rectangle {
        //     width: parent.width
        //     height: 40
        //     radius: 8
        //     color: statusColor
        //     opacity: 0.8

        //     Text {
        //         anchors.centerIn: parent
        //         text: connectionStatus + (MyTcpClient && MyTcpClient.lastError ? " - " + MyTcpClient.lastError : "")
        //         color: "white"
        //         font.pixelSize: 14
        //         font.bold: true
        //     }
        // }

        // ================== 数据展示区 ==================
        Rectangle {
            width: parent.width
            height: parent.height * 0.12
            radius: 10 * ScreenTools.scaleWidth
            color: "#15232D"
            border.color: "#2A3B4A"
            border.width: 1

            Text {
                id: flowid
                text: "流速:"
                color: "#B0BEC5"
                width: parent.width * 0.067
                style: Text.Outline
                font.pixelSize: 18 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                // width: 100
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
            }

            Text {
                id: flowrateid
                text: currentFlowRate.toFixed(2) + " L/min"  // 使用本地属性
                color: "white"
                // width: 100
                width: parent.width * 0.1333
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 18 * ScreenTools.scaleWidth
                anchors.left: flowid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10 * ScreenTools.scaleWidth
            }

            Text {
                id: leijiflowid
                text: "累计流量:"
                color: "#B0BEC5"
                width: parent.width * 0.133
                font.pixelSize: 18 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                // width: 100
                anchors.left: flowrateid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: parent.width * 0.09
            }

            Text {
                id: leijiflowshowid
                text: currentTotalVolume.toFixed(2) + "L"  // 使用本地属性
                color: "white"
                width: parent.width * 0.12
                font.pixelSize: 18 * ScreenTools.scaleWidth
                anchors.left: leijiflowid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10 * ScreenTools.scaleWidth
            }

            Text {
                id:shuixiangrongjiid
                text: "水箱容积:"
                color: "#B0BEC5"
                font.pixelSize: 18 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignRight
                width: parent.width * 0.14
                anchors.left: leijiflowshowid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: parent.width * 0.06
            }

            TextField {
                id: waterField
                placeholderText: "输入水箱容积"
                width: parent.width * 0.15
                height: parent.height * 0.6
                font.pixelSize: 18 * ScreenTools.scaleWidth
                color: "white"
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#1C2B36"
                    border.color: "#324558"
                    border.width: 1 * ScreenTools.scaleWidth
                }

                anchors.left: shuixiangrongjiid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
                // 输入验证：只允许数字
                // validator: IntValidator { bottom: 0; top: 101 }
                property real tankVolume: text ? parseFloat(text) : 0
            }



            // Text {
            //     id: shengyurongliangid
            //     text: "水箱容积:"
            //     color: "#B0BEC5"
            //     font.pixelSize: 18
            //     horizontalAlignment: Text.AlignRight
            //     width: 100
            //     anchors.left: leijiflowshowid.right
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.leftMargin: 80
            // }

            // Text {
            //     text: isConnected ? "运行中" : "待机"
            //     color: isConnected ? "#2EE59D" : "#FFA726"
            //     font.pixelSize: 18
            //     anchors.left: shengyuid.right
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.leftMargin: 20
            // }
        }

        // ================== 分割线 ==================
        Rectangle {
            width: parent.width
            height: ScreenTools.scaleWidth
            color: "#2F3E52"
            opacity: 0.7 * ScreenTools.scaleWidth
        }

        // ================== 命令输入区 ==================
        Row {
            spacing: ScreenTools.scaleWidth * 20
            width: parent.width
            height: parent.height * 0.12

            Text {
                id: setflowid
                text: "设置流速:"
                color: "#B0BEC5"
                style: Text.Outline
                font.pixelSize: 22 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.17
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id: cmdField
                placeholderText: "输入流速值 (0-100)"
                width: parent.width * 0.25
                height: parent.height * 0.6
                font.pixelSize: 18 * ScreenTools.scaleWidth
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#1C2B36"
                    border.color: "#324558"
                    border.width: 1 * ScreenTools.scaleWidth
                }
                // 输入验证：只允许数字
                validator: IntValidator { bottom: 0; top: 101 }
            }

            Button {
                id:send_button
                width: parent.width * 0.2
                height: parent.height * 0.6
                text: "发送"
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 16 * ScreenTools.scaleWidth
                enabled: isConnected && cmdField.text !== ""
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: enabled ? "#00E5FF" : "#666666"
                }
                onClicked: {
                    if (MyTcpClient && isConnected) {
                        MyTcpClient.sendMessage(cmdField.text)
                        cmdField.text = "" // 清空输入框
                    }
                }
            }
            Text {
                id: shuixiangshengyuid
                text: "水箱剩余:0.0 L"
                color: "#B0BEC5"
                font.pixelSize: 22 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.17
                anchors.verticalCenter: parent.verticalCenter
                // anchors.left: send_button.right
                // anchors.verticalCenter: parent.verticalCenter
                // anchors.leftMargin: 20
            }
        }

        // ================== 连接按钮区域 ==================
        Rectangle {
            width: parent.width
            height: parent.height * 0.15
            radius: 10 * ScreenTools.scaleWidth
            color: "#15232D"
            border.color: "#2A3B4A"
            border.width: 1 * ScreenTools.scaleWidth

            Text {
                id: ipid
                text: "IP地址:"
                color: "#B0BEC5"
                style: Text.Outline
                font.pixelSize: 20 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.133
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
            }

            TextField {
                id: ipField
                placeholderText: "192.168.3.128"
                width: parent.width * 0.23
                height: parent.height * 0.8
                font.pixelSize: 18 * ScreenTools.scaleWidth
                color: "white"
                anchors.left: ipid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10 * ScreenTools.scaleWidth
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#1C2B36"
                    border.color: "#324558"
                    border.width: 1 * ScreenTools.scaleWidth
                }
                // 设置默认值
                Component.onCompleted: text = "192.168.3.128"
            }

            Text {
                id: portid
                text: "端口:"
                color: "#B0BEC5"
                style: Text.Outline
                font.pixelSize: 18 * ScreenTools.scaleWidth
                horizontalAlignment: Text.AlignLeft
                width: parent.width * 0.083
                anchors.left: ipField.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
            }

            TextField {
                id: portField
                placeholderText: "6000"
                width: parent.width * 0.133
                height: parent.height * 0.8
                color: "white"
                font.pixelSize: 18 * ScreenTools.scaleWidth
                anchors.left: portid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: "#1C2B36"
                    border.color: "#324558"
                    border.width: 1 * ScreenTools.scaleWidth
                }
                validator: IntValidator { bottom: 1; top: 65535 }
                // 设置默认值
                Component.onCompleted: text = "10000"
            }

            // Rectangle {
            //     width: 80
            //     height: 40
            //     radius: 8
            //     color: statusColor
            //     opacity: 0.8
            //     anchors.left: portField.right
            //     anchors.verticalCenter: parent.verticalCenter
            //     anchors.leftMargin: 20

            //     Text {
            //         anchors.centerIn: parent
            //         text: connectionStatus + (MyTcpClient && MyTcpClient.lastError ? " - " + MyTcpClient.lastError : "")
            //         color: "white"
            //         font.pixelSize: 14
            //         font.bold: true
            //     }
            // }

            Button {
                id: connectButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 20 * ScreenTools.scaleWidth
                width: parent.width * 0.2
                height: parent.height * 0.7
                text: {
                    if (!MyTcpClient) return "未初始化"
                    if (isConnected) return "断开连接"
                    if (isConnecting) return "连接中..."
                    return "连接机载电脑"
                }
                font.pixelSize: 16 * ScreenTools.scaleWidth
                background: Rectangle {
                    radius: 6 * ScreenTools.scaleWidth
                    color: {
                        if (!MyTcpClient) return "#666666"
                        if (isConnected) return "#FF6B6B"
                        if (isConnecting) return "#FFA726"
                        return "#2EE59D"
                    }
                    border.color: {
                        if (!MyTcpClient) return "#666666"
                        if (isConnected) return "#FF6B6B"
                        if (isConnecting) return "#FFA726"
                        return "#2EE59D"
                    }
                }
                onClicked: {
                    if (!MyTcpClient) {
                        console.error("MyTcpClient 未初始化")
                        return
                    }

                    if (isConnected) {
                        // 断开连接
                        console.log("断开连接")
                        MyTcpClient.disconnectFromHost()
                    } else if (!isConnecting) {
                        // 从输入框获取IP和端口
                        var ip = ipField.text
                        var port = parseInt(portField.text)

                        if (ip && port) {
                            console.log("尝试连接到:", ip + ":" + port)
                            // 调用连接函数
                            MyTcpClient.connectToHost(ip, port)
                        } else {
                            console.error("IP或端口无效")
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 40 * ScreenTools.scaleWidth
            radius: 8 * ScreenTools.scaleWidth
            color: statusColor
            opacity: 0.8 * ScreenTools.scaleWidth

            Text {
                anchors.centerIn: parent
                text: connectionStatus + (MyTcpClient && MyTcpClient.lastError ? " - " + MyTcpClient.lastError : "")
                color: "white"
                font.pixelSize: 14* ScreenTools.scaleWidth
                font.bold: true
            }
        }
         Rectangle {
             width: parent.width
                    height: 60 * ScreenTools.scaleWidth
                    radius: 8 * ScreenTools.scaleWidth
                    color: "#2A3B4A"
                    visible: true // 设置为true显示调试信息

        MissionOptionRow {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20 * ScreenTools.scaleWidth
            // visible: isclean =1
            labelText: qsTr("清洗开关")
            options: [qsTr("开始清洗"), qsTr("暂停清洗")]
            selectedIndex: isopen_pump
            onSelectionChanged: function(index) {
                isopen_pump = index
                MyTcpClient.send_isopen_pump(isopen_pump);
            }
        }
         }

        // ================== 调试信息显示 ==================
        // Rectangle {
        //     width: parent.width
        //     height: 60
        //     radius: 8
        //     color: "#2A3B4A"
        //     visible: true // 设置为true显示调试信息

        //     Column {
        //         anchors.centerIn: parent
        //         spacing: 2
        //         Text {
        //             text: "调试信息:"
        //             color: "#B0BEC5"
        //             font.pixelSize: 12
        //             font.bold: true
        //         }
        //         Text {
        //             text: "连接状态: " + (MyTcpClient ?
        //                  (MyTcpClient.connected ? "已连接" :
        //                   (MyTcpClient.connecting ? "连接中" : "未连接")) : "未初始化")
        //             color: "#B0BEC5"
        //             font.pixelSize: 10
        //         }
        //         Text {
        //             text: "最后错误: " + (MyTcpClient ? MyTcpClient.lastError : "无")
        //             color: "#B0BEC5"
        //             font.pixelSize: 10
        //         }
        //     }
        // }
    }

    // ================== 手动信号连接和定时更新 ==================
    Timer {
        interval: 100 // 100ms刷新一次
        running: true
        repeat: true
        onTriggered: {
            if (PumpModel) {
                // 使用Q_INVOKABLE方法获取值
                var flowRate = PumpModel.getFlowRateValue()
                var totalVolume = PumpModel.getTotalVolumeValue()

                // 更新本地属性
                if (currentFlowRate !== flowRate) {
                    currentFlowRate = flowRate
                }
                if (currentTotalVolume !== totalVolume) {
                    currentTotalVolume = totalVolume
                }

                var remainingVolume = waterField.tankVolume - totalVolume
                           // 确保剩余流量不为负数
                           remainingVolume = Math.max(0, remainingVolume)

                           // 更新剩余流量显示
                           shuixiangshengyuid.text = "剩余容积: " + remainingVolume.toFixed(2) + " L"

                if (waterField.tankVolume>0 && remainingVolume<=1)
                {
                    VkSdkInstance.vehicleManager.activeVehicle.returnMission("NaN",0) // 执行自动返航，直线返航
                }

                // 调试输出
                if (flowRate > 0 || totalVolume > 0) {
                    console.log("定时更新 - 流速:", flowRate, "累计:", totalVolume)
                }
            }
        }
    }

    // ================== 组件初始化调试 ==================
    Component.onCompleted: {
        console.log("=== QML组件初始化 ===")
        console.log("PumpModel 对象:", PumpModel)
        console.log("MyTcpClient 对象:", MyTcpClient)

        // 测试Q_INVOKABLE方法
        if (PumpModel) {
            console.log("测试Q_INVOKABLE方法...")
            console.log("getFlowRateValue:", PumpModel.getFlowRateValue())
            console.log("getTotalVolumeValue:", PumpModel.getTotalVolumeValue())
        }
    }
}
