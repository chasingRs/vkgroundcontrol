import QtQuick 2.15
import QtQuick.Controls 2.15
import Controls 1.0
import FlightDisplay 1.0
import VkSdkInstance
import ScreenTools 1.0

import "qrc:/qml/FlightDisplay" as Shared

Rectangle {
    id: root
    anchors.fill: parent
    color: "#101820"
    signal closeRequested()
    signal lowWaterLevelAlert()  // 低液位警报信号

    // ================== 连接与泵状态属性 ==================
    property int isopen_pump: 1
    property int init_pump: 0
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

    // ================== 流量数据属性 ==================
    property double currentFlowRate: 0.0
    property double currentTotalVolume: 0.0

    // ================== 调试模式控制 ==================
    readonly property bool debugModeEnabled: true 

    // ================== 自动返航状态管理 ==================
    property bool lowWaterLevelDetected: false          // 是否检测到低液位
    property bool isReturningForRefill: false           // 是否正在返航加水
    property bool isReturningToWork: false              // 是否正在返回工作点
    
    // 任务航点保存 - 记录缺水时执行到的航点序号，用于加水后从该航点继续工作
    property int savedMissionWaypointIndex: -1          

    // 获取当前飞机位置
    property var activeVehicle: VkSdkInstance.vehicleManager.activeVehicle
    property var currentCoordinate: activeVehicle ? activeVehicle.coordinate : null

    // ================== 界面布局 ==================
    Column {
        anchors.centerIn: parent
        spacing: 18 * ScreenTools.scaleWidth
        width: parent.width * 0.9
        height: parent.height * 0.9

        // 1. 标题和顶部按钮区域
        Rectangle {
            width: parent.width
            height: parent.height * 0.15
            color: "transparent"

            Row {
                anchors.fill: parent
                spacing: 20 * ScreenTools.scaleWidth

                // 左侧按钮组
                Column {
                    width: (parent.width - 60 * ScreenTools.scaleWidth) / 3
                    height: parent.height
                    spacing: 15 * ScreenTools.scaleWidth
                    anchors.verticalCenter: parent.verticalCenter

                    // 返回按钮
                    Button {
                        id: rtn_btn
                        width: parent.width
                        height: 55 * ScreenTools.scaleWidth
                        text: "返回"
                        font.pixelSize: 20 * ScreenTools.scaleWidth
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter

                        background: Rectangle {
                            radius: 10 * ScreenTools.scaleWidth
                            color: parent.pressed ? "#1B5E20" : "#2EE59D"
                            border.color: "#A5D6A7"
                            border.width: 2
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "#000000"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: closeRequested()
                    }

                    // 测试模式开关
                    Button {
                        id: testModeButton
                        visible: debugModeEnabled
                        width: parent.width
                        height: 55 * ScreenTools.scaleWidth
                        text: testModeSwitch ? "🧪 测试ON" : "🧪 测试OFF"
                        font.pixelSize: 18 * ScreenTools.scaleWidth
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        property bool testModeSwitch: false

                        background: Rectangle {
                            radius: 10 * ScreenTools.scaleWidth
                            color: testModeButton.testModeSwitch ? "#FF9800" : "#546E7A"
                            border.color: testModeButton.testModeSwitch ? "#FFB74D" : "#78909C"
                            border.width: 2
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            testModeSwitch = !testModeSwitch
                            console.log("测试模式:", testModeSwitch ? "开启" : "关闭")
                        }
                    }
                }

                // 中间标题
                Text {
                    id: header
                    text: "💧 水泵实时监控"
                    width: (parent.width - 60 * ScreenTools.scaleWidth) / 3
                    height: parent.height
                    color: "#00E5FF"
                    font.bold: true
                    font.pixelSize: 32 * ScreenTools.scaleWidth
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // 右侧按钮组
                Column {
                    width: (parent.width - 60 * ScreenTools.scaleWidth) / 3
                    height: parent.height
                    spacing: 15 * ScreenTools.scaleWidth
                    anchors.verticalCenter: parent.verticalCenter

                    // 初始化按钮
                    Button {
                        width: parent.width
                        height: 55 * ScreenTools.scaleWidth
                        text: "初始化"
                        font.pixelSize: 20 * ScreenTools.scaleWidth
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter

                        background: Rectangle {
                            radius: 10 * ScreenTools.scaleWidth
                            color: parent.pressed ? "#00ACC1" : "#00BCD4"
                            border.color: "#80DEEA"
                            border.width: 2
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            init_pump = 1;
                            MyTcpClient.send_init_pump(init_pump);
                        }
                    }

                    // 模拟自动返航按钮 (调试用)
                    Button {
                        visible: debugModeEnabled
                        width: parent.width
                        height: 55 * ScreenTools.scaleWidth
                        text: "🧪 模拟自动返航"
                        font.pixelSize: 18 * ScreenTools.scaleWidth
                        font.bold: true
                        enabled: testModeButton.testModeSwitch
                        anchors.horizontalCenter: parent.horizontalCenter

                        background: Rectangle {
                            radius: 8 * ScreenTools.scaleWidth
                            color: parent.enabled ? (parent.pressed ? "#D84315" : "#FF6B6B") : "#37474F"
                            border.color: parent.enabled ? "#FFCDD2" : "#546E7A"
                            border.width: 2
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: parent.enabled ? "white" : "#90A4AE"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            // 模拟记录当前航点序号
                            if (activeVehicle && activeVehicle.missionCurrent) {
                                savedMissionWaypointIndex = activeVehicle.missionCurrent.missionCurrentSeq
                            } else {
                                savedMissionWaypointIndex = 0 // 模拟航点
                            }

                            // 触发状态
                            lowWaterLevelDetected = true
                            isReturningForRefill = true
                            
                            // 模拟返航指令
                            if(activeVehicle) {
                                activeVehicle.returnMission(NaN, 0)
                            }
                            
                            // 直接打开状态通知
                            returnStatusNotification.open()
                        }
                    }
                }
            }
        }

        // 2. 返航状态指示按钮 (仅在触发后显示)
        Rectangle {
            id: lowWaterWarningButton
            visible: lowWaterLevelDetected || isReturningForRefill || isReturningToWork
            width: parent.width
            height: 70 * ScreenTools.scaleWidth
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter

            Button {
                width: 380 * ScreenTools.scaleWidth
                height: 60 * ScreenTools.scaleWidth
                anchors.centerIn: parent

                background: Rectangle {
                    radius: 12 * ScreenTools.scaleWidth
                    color: isReturningForRefill ? '#f70606' : "#2EE59D"
                    border.color: (isReturningForRefill || isReturningToWork) ? "#A5D6A7" : "#FFD600"
                    border.width: 4

                    // 呼吸效果
                    SequentialAnimation on opacity {
                        running: lowWaterWarningButton.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.8; duration: 1000 }
                        NumberAnimation { from: 0.8; to: 1.0; duration: 1000 }
                    }
                }

                contentItem: Row {
                    spacing: 12 * ScreenTools.scaleWidth
                    anchors.centerIn: parent

                    Text {
                        text: isReturningToWork ? "✈️" : "🚁"
                        font.pixelSize: 28 * ScreenTools.scaleWidth
                        color: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: {
                            if (isReturningToWork) return "正在返回工作点 - 点击详情"
                            return "低液位警告⚠ 返航加水中 - 点击详情"
                        }
                        font.pixelSize: 20 * ScreenTools.scaleWidth
                        font.bold: true
                        color: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                onClicked: {
                    // 点击后打开状态通知详情
                    returnStatusNotification.open()
                }
            }
        }

        // 3. 数据展示区
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
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20 * ScreenTools.scaleWidth
            }

            Text {
                id: flowrateid
                text: currentFlowRate.toFixed(2) + " L/min"
                color: "white"
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
                anchors.left: flowrateid.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: parent.width * 0.09
            }

            Text {
                id: leijiflowshowid
                text: currentTotalVolume.toFixed(2) + "L"
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
                property real tankVolume: text ? parseFloat(text) : 0
            }
        }

        // 分割线
        Rectangle {
            width: parent.width
            height: ScreenTools.scaleWidth
            color: "#2F3E52"
            opacity: 0.7 * ScreenTools.scaleWidth
        }

        // 4. 命令输入区
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
                        cmdField.text = ""
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
            }
        }

        // 5. 连接按钮区域
        Rectangle {
            width: parent.width
            height: parent.height * 0.1
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
                placeholderText: "192.168.144.108"
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
                Component.onCompleted: text = "192.168.144.108"
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
                Component.onCompleted: text = "6000"
            }

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
                    border.color: color
                }
                onClicked: {
                    if (!MyTcpClient) return
                    if (isConnected) {
                        MyTcpClient.disconnectFromHost()
                    } else if (!isConnecting) {
                        var ip = ipField.text
                        var port = parseInt(portField.text)
                        if (ip && port) MyTcpClient.connectToHost(ip, port)
                    }
                }
            }
        }

        // 状态信息条
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

        // 清洗开关控制
        Rectangle {
            width: parent.width
            height: 60 * ScreenTools.scaleWidth
            radius: 8 * ScreenTools.scaleWidth
            color: "#2A3B4A"
            visible: true

            MissionOptionRow {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 100 * ScreenTools.scaleWidth
                labelText: qsTr("清洗开关")
                options: [qsTr("开始清洗"), qsTr("暂停清洗")]
                selectedIndex: isopen_pump
                onSelectionChanged: function(index) {
                    isopen_pump = index
                    MyTcpClient.send_isopen_pump(isopen_pump);
                }
            }
        }
    }

    // ================== 定时器：数据更新与自动返航逻辑 ==================
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (PumpModel) {
                var flowRate = PumpModel.getFlowRateValue()
                var totalVolume = PumpModel.getTotalVolumeValue()

                if (currentFlowRate !== flowRate) currentFlowRate = flowRate
                if (currentTotalVolume !== totalVolume) currentTotalVolume = totalVolume

                var remainingVolume = waterField.tankVolume - totalVolume
                remainingVolume = Math.max(0, remainingVolume)
                shuixiangshengyuid.text = "剩余容积: " + remainingVolume.toFixed(2) + " L"

                // --- 自动返航逻辑 ---
                if (waterField.tankVolume > 0 && totalVolume > 0 && remainingVolume <= 1) {
                    // 检测到低液位
                    if (!lowWaterLevelDetected) {
                        lowWaterLevelDetected = true
                        console.log("🚨 检测到低液位 - 准备自动返航")

                        // 1. 记录断点航点
                        if (activeVehicle && activeVehicle.missionCurrent) {
                            savedMissionWaypointIndex = activeVehicle.missionCurrent.missionCurrentSeq
                            console.log("🔖 航点已保存:", savedMissionWaypointIndex)
                        } else {
                            savedMissionWaypointIndex = -1
                        }

                        // 2. 自动执行返航 (如果尚未在执行)
                        if (!isReturningForRefill) {
                            isReturningForRefill = true
                            
                            // 呼叫父组件警报
                            lowWaterLevelAlert()
                            
                            // 显示状态通知
                            returnStatusNotification.open()
                            
                            // 发送返航指令
                            if (activeVehicle) {
                                // 关闭水泵
                                Shared.AppState.isopen_pump = 1 ;
                                MyTcpClient.send_isopen_pump(Shared.AppState.isopen_pump);
                                activeVehicle.returnMission(NaN, 0) // 直线返航
                                console.log("✈️ 自动返航指令已发送")
                            }
                        }
                    }
                } else if (remainingVolume > 1) {
                    // 液位恢复且不在任务流程中时，重置标志
                    if (!isReturningForRefill && !isReturningToWork) {
                        lowWaterLevelDetected = false
                    }
                }
            }
        }
    }

    // ================== 调试信息组件 ==================
    Component.onCompleted: {
        if (debugModeEnabled) {
            console.log("=== QML组件初始化: 自动返航模式 ===")
        }
    }

    // ================== 返航状态通知框 ==================
    // 替代了原本的询问对话框，现在直接显示状态
    Dialog {
        id: returnStatusNotification
        modal: false
        x: parent.width - width - 20 * ScreenTools.scaleWidth
        y: 20 * ScreenTools.scaleWidth
        width: 350 * ScreenTools.scaleWidth
        closePolicy: Dialog.NoAutoClose

        background: Rectangle {
            color: "#1E2A35"
            border.color: "#2EE59D"
            border.width: 2
            radius: 10
        }

        contentItem: Column {
            spacing: 15 * ScreenTools.scaleWidth
            padding: 15 * ScreenTools.scaleWidth

            Row {
                spacing: 10 * ScreenTools.scaleWidth

                Rectangle {
                    width: 10 * ScreenTools.scaleWidth
                    height: 10 * ScreenTools.scaleWidth
                    radius: 5 * ScreenTools.scaleWidth
                    color: "#2EE59D"

                    SequentialAnimation on opacity {
                        running: returnStatusNotification.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                        NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                    }
                }

                Text {
                    text: isReturningToWork ? "✈️ 正在返回工作点..." : "🚁 自动返航加水中..."
                    font.pixelSize: 16 * ScreenTools.scaleWidth
                    font.bold: true
                    color: "#2EE59D"
                }
            }

            Text {
                text: isReturningToWork ? "即将到达工作点,继续作业" : "水箱缺水触发自动返航,加水后可返回"
                font.pixelSize: 13 * ScreenTools.scaleWidth
                color: "#B0BEC5"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Row {
                spacing: 12 * ScreenTools.scaleWidth
                anchors.horizontalCenter: parent.horizontalCenter

                // "返回工作点" 按钮：加水完成后点击
                Button {
                    visible: !isReturningToWork
                    text: "返回工作点"
                    width: 160 * ScreenTools.scaleWidth
                    height: 45 * ScreenTools.scaleWidth
                    font.pixelSize: 15 * ScreenTools.scaleWidth
                    font.bold: true
                    enabled: savedMissionWaypointIndex >= 0

                    background: Rectangle {
                        radius: 8 * ScreenTools.scaleWidth
                        color: parent.enabled ? (parent.pressed ? "#1B5E20" : "#2EE59D") : "#555555"
                        border.width: 2
                        border.color: parent.enabled ? "#A5D6A7" : "#777777"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: parent.enabled ? "#000000" : "#999999"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (savedMissionWaypointIndex >= 0) {
                            returnToWorkConfirmDialog.open()
                        }
                    }
                }

                // "已完成" 按钮：返回工作点后点击结束流程
                Button {
                    visible: isReturningToWork
                    text: "✅ 已完成"
                    width: 140 * ScreenTools.scaleWidth
                    height: 45 * ScreenTools.scaleWidth
                    font.pixelSize: 15 * ScreenTools.scaleWidth
                    font.bold: true

                    background: Rectangle {
                        radius: 8 * ScreenTools.scaleWidth
                        color: parent.pressed ? "#1B5E20" : "#2EE59D"
                        border.width: 2
                        border.color: "#A5D6A7"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#000000"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        // 重置所有状态
                        isReturningToWork = false
                        isReturningForRefill = false
                        lowWaterLevelDetected = false
                        savedMissionWaypointIndex = -1
                        returnStatusNotification.close()
                    }
                }

                // 关闭按钮
                Button {
                    text: "隐藏"
                    width: 80 * ScreenTools.scaleWidth
                    height: 45 * ScreenTools.scaleWidth
                    font.pixelSize: 15 * ScreenTools.scaleWidth
                    font.bold: true

                    background: Rectangle {
                        radius: 8 * ScreenTools.scaleWidth
                        color: parent.pressed ? "#424242" : "#666666"
                        border.width: 2
                        border.color: "#999999"
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: returnStatusNotification.close()
                }
            }
        }
    }

    // ================== 返回工作点二次确认框 ==================
    Dialog {
        id: returnToWorkConfirmDialog
        title: "✈️ 确认返回工作点"
        modal: true
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 420 * ScreenTools.scaleWidth
        closePolicy: Dialog.CloseOnEscape

        background: Rectangle {
            color: "#1E2A35"
            border.color: "#2EE59D"
            border.width: 2
            radius: 10
        }

        contentItem: Column {
            spacing: 20 * ScreenTools.scaleWidth
            padding: 20 * ScreenTools.scaleWidth

            Text {
                text: "✈️ 确认返回工作点"
                font.pixelSize: 18 * ScreenTools.scaleWidth
                font.bold: true
                color: "#2EE59D"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: 1
                color: "#2A3B4A"
            }

            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: 60 * ScreenTools.scaleWidth
                color: "#2A3B4A"
                radius: 8
                Column {
                    anchors.centerIn: parent
                    spacing: 5 * ScreenTools.scaleWidth
                    Text {
                        text: "将前往断点: 航点 #" + savedMissionWaypointIndex
                        font.pixelSize: 14 * ScreenTools.scaleWidth
                        color: "#00E5FF"
                    }
                }
            }

            Text {
                text: "确认已完成加水,准备返回工作点继续作业?"
                font.pixelSize: 14 * ScreenTools.scaleWidth
                color: "#FFB74D"
                wrapMode: Text.WordWrap
                width: parent.width - 40 * ScreenTools.scaleWidth
            }

            Row {
                spacing: 20 * ScreenTools.scaleWidth
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: "取消"
                    width: 140 * ScreenTools.scaleWidth
                    height: 55 * ScreenTools.scaleWidth
                    font.pixelSize: 17 * ScreenTools.scaleWidth
                    font.bold: true
                    background: Rectangle {
                        radius: 10 * ScreenTools.scaleWidth
                        color: parent.pressed ? "#424242" : "#666666"
                        border.color: "#999999"
                        border.width: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: returnToWorkConfirmDialog.close()
                }

                Button {
                    text: "✅ 确认返回"
                    width: 160 * ScreenTools.scaleWidth
                    height: 55 * ScreenTools.scaleWidth
                    font.pixelSize: 17 * ScreenTools.scaleWidth
                    font.bold: true
                    background: Rectangle {
                        radius: 10 * ScreenTools.scaleWidth
                        color: parent.pressed ? "#1B5E20" : "#2EE59D"
                        border.color: "#A5D6A7"
                        border.width: 2
                    }
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#000000"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (savedMissionWaypointIndex >= 0) {
                            console.log("🔙 确认返回工作点:", savedMissionWaypointIndex)
                            isReturningToWork = true
                            isReturningForRefill = false
                            
                            // 从保存的航点继续执行任务
                            if (activeVehicle) {
                                activeVehicle.startMission(savedMissionWaypointIndex, 0, 0)
                            }
                            returnToWorkConfirmDialog.close()
                        }
                    }
                }
            }
        }
    }
}
