import QtQuick 2.15
import QtQuick.Controls 2.15
import Controls 1.0
import FlightDisplay 1.0
import VkSdkInstance
import ScreenTools 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "#101820"
    signal closeRequested()
    signal lowWaterLevelAlert()  // 低液位警报信号，通知父组件打开对话框

    // 使用新的连接状态属性
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

    // 添加本地属性来存储值
    property double currentFlowRate: 0.0
    property double currentTotalVolume: 0.0

    // ================== 调试模式控制 ==================
    // 设置为 false 可以完全禁用所有调试功能
    readonly property bool debugModeEnabled: false
    
    // ================== 低液位返航状态管理 ==================
    property bool lowWaterLevelDetected: false          // 是否检测到低液位
    property bool isReturningForRefill: false           // 是否正在返航加水
    property bool isReturningToWork: false              // 是否正在返回工作点
    property bool hasShownLowWaterDialog: false         // 是否已显示低液位对话框(防止重复弹出)
    
    // 任务航点保存 - 记录缺水时执行到的航点序号，用于加水后从该航点继续工作
    property int savedMissionWaypointIndex: -1          // 记录缺水时的航点索引 (-1表示未保存)
    
    // 获取当前飞机位置
    property var activeVehicle: VkSdkInstance.vehicleManager.activeVehicle
    property var currentCoordinate: activeVehicle ? activeVehicle.coordinate : null

    // 整体布局：垂直分三部分
    Column {
        anchors.centerIn: parent
        spacing: 18 * ScreenTools.scaleWidth
        width: parent.width * 0.9
        height: parent.height * 0.9

        // ================== 标题和按钮布局区域 ==================
        Rectangle {
            width: parent.width
            height: parent.height * 0.2
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
                    
                    // 测试模式开关按钮
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
                    
                    // 模拟低液位按钮
                    Button {
                        visible: debugModeEnabled
                        width: parent.width
                        height: 55 * ScreenTools.scaleWidth
                        text: "🧪 模拟低液位"
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
                                console.log("模拟记录航点序号:", savedMissionWaypointIndex)
                            } else {
                                // 如果没有真实飞机,使用模拟航点序号
                                savedMissionWaypointIndex = 0
                                console.log("使用模拟航点序号(无飞机连接):", savedMissionWaypointIndex)
                            }
                            
                            // 重置标志以允许弹出对话框
                            hasShownLowWaterDialog = false
                            lowWaterLevelDetected = true
                            
                            // 直接打开低液位对话框
                            lowWaterDialog.open()
                        }
                    }
                }
            }
        }

        // ================== 低液位警告/返航状态按钮 ==================
        Rectangle {
            id: lowWaterWarningButton
            // 在以下情况显示：1) 检测到低液位 或 2) 正在返航加水 或 3) 正在返回工作点
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
                    // 根据状态显示不同颜色
                    color: {
                        if (isReturningForRefill || isReturningToWork) {
                            return parent.pressed ? "#1B5E20" : "#2EE59D"  // 返航中显示绿色
                        } else {
                            return parent.pressed ? "#D32F2F" : "#FF6B6B"  // 警告时显示红色
                        }
                    }
                    border.color: (isReturningForRefill || isReturningToWork) ? "#A5D6A7" : "#FFD600"
                    border.width: 4
                    
                    // 闪烁效果 - 只在未返航时闪烁
                    SequentialAnimation on opacity {
                        running: lowWaterWarningButton.visible && !isReturningForRefill && !isReturningToWork
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.6; duration: 600 }
                        NumberAnimation { from: 0.6; to: 1.0; duration: 600 }
                    }
                    
                    // 返航中的呼吸效果
                    SequentialAnimation on opacity {
                        running: lowWaterWarningButton.visible && (isReturningForRefill || isReturningToWork)
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.8; duration: 1000 }
                        NumberAnimation { from: 0.8; to: 1.0; duration: 1000 }
                    }
                }
                
                contentItem: Row {
                    spacing: 12 * ScreenTools.scaleWidth
                    anchors.centerIn: parent
                    
                    // 左侧图标
                    Text {
                        text: {
                            if (isReturningToWork) return "✈️"
                            if (isReturningForRefill) return "🚁"
                            return "⚠️"
                        }
                        font.pixelSize: 28 * ScreenTools.scaleWidth
                        color: (isReturningForRefill || isReturningToWork) ? "#000000" : "#FFD600"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    // 中间文本
                    Text {
                        text: {
                            if (isReturningToWork) return "正在返回工作点 - 点击查看详情"
                            if (isReturningForRefill) return "正在返航加水 - 点击查看详情"
                            return "液位过低 - 点击返航加水"
                        }
                        font.pixelSize: 20 * ScreenTools.scaleWidth
                        font.bold: true
                        color: (isReturningForRefill || isReturningToWork) ? "#000000" : "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    // 右侧图标
                    Text {
                        text: {
                            if (isReturningToWork) return "✈️"
                            if (isReturningForRefill) return "🚁"
                            return "⚠️"
                        }
                        font.pixelSize: 28 * ScreenTools.scaleWidth
                        color: (isReturningForRefill || isReturningToWork) ? "#000000" : "#FFD600"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                onClicked: {
                    // 根据状态打开不同的对话框
                    if (isReturningForRefill || isReturningToWork) {
                        returnStatusNotification.open()
                    } else {
                        lowWaterDialog.open()
                    }
                }
            }
        }

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

                // ================== 低液位检测与返航逻辑 ==================
                if (waterField.tankVolume > 0 && totalVolume > 0 && remainingVolume <= 1) {
                    if (!lowWaterLevelDetected) {
                        // 首次检测到低液位
                        lowWaterLevelDetected = true
                        
                        // 记录当前执行的航点序号和任务模式
                        if (activeVehicle && activeVehicle.missionCurrent) {
                            savedMissionWaypointIndex = activeVehicle.missionCurrent.missionCurrentSeq
                            console.log("🔖 记录当前航点序号:", savedMissionWaypointIndex)
                        } else {
                            savedMissionWaypointIndex = -1
                            console.warn("⚠️ 无法获取当前任务信息，航点序号记录失败")
                        }
                        
                        // 只在首次检测到低液位时自动弹出对话框
                        if (!hasShownLowWaterDialog) {
                            hasShownLowWaterDialog = true
                            
                            // 发出低液位警报信号，通知父组件打开对话框
                            lowWaterLevelAlert()
                            
                            // 打开内部的低液位对话框
                            lowWaterDialog.open()
                        }
                    }
                } else if (remainingVolume > 1) {
                    // 液位恢复正常
                    // 只有在未返航的情况下才重置低液位标志
                    if (!isReturningForRefill && !isReturningToWork) {
                        lowWaterLevelDetected = false
                    }
                    // 注意: hasShownLowWaterDialog 不重置,直到用户手动操作
                }

                // 调试输出
                if (flowRate > 0 || totalVolume > 0) {
                    console.log("定时更新 - 流速:", flowRate, "累计:", totalVolume)
                }
            }
        }
    }

    // ==================== 调试功能: 组件初始化调试 BEGIN ====================
    Component.onCompleted: {
        if (debugModeEnabled) {
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
    // ==================== 调试功能: 组件初始化调试 END ====================

    // ==================== 调试功能: 测试状态指示器 BEGIN ====================
    // 后期发布时,设置 debugModeEnabled = false 即可完全禁用
    Rectangle {
        id: testStatusIndicator
        visible: debugModeEnabled && testModeButton.testModeSwitch  // 调试模式控制
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 10 * ScreenTools.scaleWidth
        anchors.leftMargin: 10 * ScreenTools.scaleWidth
        width: 320 * ScreenTools.scaleWidth
        height: testStatusColumn.height + 20 * ScreenTools.scaleWidth
        color: "#1E2A35"
        border.color: "#FF9800"
        border.width: 2
        radius: 8
        z: 1000
        
        Column {
            id: testStatusColumn
            anchors.centerIn: parent
            spacing: 5 * ScreenTools.scaleWidth
            width: parent.width - 20 * ScreenTools.scaleWidth
            
            Text {
                text: "🧪 测试模式状态"
                font.pixelSize: 14 * ScreenTools.scaleWidth
                font.bold: true
                color: "#FF9800"
                width: parent.width
            }
            
            Rectangle { width: parent.width; height: 1; color: "#455A64" }
            
            Row {
                spacing: 10 * ScreenTools.scaleWidth
                Text {
                    text: "低液位检测:"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: "#B0BEC5"
                }
                Text {
                    text: lowWaterLevelDetected ? "✓ 已触发" : "○ 未触发"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: lowWaterLevelDetected ? "#FF6B6B" : "#66BB6A"
                }
            }
            
            Row {
                spacing: 10 * ScreenTools.scaleWidth
                Text {
                    text: "对话框显示:"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: "#B0BEC5"
                }
                Text {
                    text: hasShownLowWaterDialog ? "✓ 已显示" : "○ 未显示"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: hasShownLowWaterDialog ? "#2EE59D" : "#666666"
                }
            }
            
            Row {
                spacing: 10 * ScreenTools.scaleWidth
                Text {
                    text: "返航状态:"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: "#B0BEC5"
                }
                Text {
                    text: isReturningForRefill ? "✓ 返航中" : "○ 未返航"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: isReturningForRefill ? "#00E5FF" : "#666666"
                }
            }
            
            Row {
                spacing: 10 * ScreenTools.scaleWidth
                Text {
                    text: "警告按钮:"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: "#B0BEC5"
                }
                Text {
                    text: lowWaterWarningButton.visible ? "✓ 显示中" : "○ 隐藏"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: lowWaterWarningButton.visible ? "#FFD600" : "#666666"
                }
            }
            
            Row {
                spacing: 10 * ScreenTools.scaleWidth
                Text {
                    text: "航点索引:"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: "#B0BEC5"
                }
                Text {
                    text: savedMissionWaypointIndex >= 0 ? ("✓ " + savedMissionWaypointIndex) : "○ 未记录"
                    font.pixelSize: 12 * ScreenTools.scaleWidth
                    color: savedMissionWaypointIndex >= 0 ? "#2EE59D" : "#666666"
                }
            }
            
            Rectangle { width: parent.width; height: 1; color: "#455A64" }
            
            // 快捷操作按钮
            Row {
                spacing: 5 * ScreenTools.scaleWidth
                width: parent.width
                
                Button {
                    text: "重置状态"
                    width: (parent.width - 5 * ScreenTools.scaleWidth) / 2
                    height: 28 * ScreenTools.scaleWidth
                    font.pixelSize: 11 * ScreenTools.scaleWidth
                    
                    background: Rectangle {
                        radius: 4
                        color: parent.pressed ? "#455A64" : "#546E7A"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("🔄 重置测试状态")
                        lowWaterLevelDetected = false
                        hasShownLowWaterDialog = false
                        isReturningForRefill = false
                        isReturningToWork = false
                        savedMissionWaypointIndex = -1
                        lowWaterDialog.close()
                        returnStatusNotification.close()
                    }
                }
                
                Button {
                    text: "打开通知"
                    width: (parent.width - 5 * ScreenTools.scaleWidth) / 2
                    height: 28 * ScreenTools.scaleWidth
                    font.pixelSize: 11 * ScreenTools.scaleWidth
                    
                    background: Rectangle {
                        radius: 4
                        color: parent.pressed ? "#00ACC1" : "#00BCD4"
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        isReturningForRefill = true
                        if (savedMissionWaypointIndex < 0) {
                            savedMissionWaypointIndex = 0  // 模拟第一个航点
                        }
                        returnStatusNotification.open()
                    }
                }
            }
        }
    }
    // ==================== 调试功能: 测试状态指示器 END ====================

    // ================== 低液位返航对话框 ==================
    Dialog {
        id: lowWaterDialog
        title: "⚠️ 低液位警告"
        modal: true
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 600 * ScreenTools.scaleWidth)
        
        background: Rectangle {
            color: "#1E2A35"
            border.color: "#FF6B6B"
            border.width: 2
            radius: 10
        }
        
        header: Rectangle {
            width: parent.width
            height: 60 * ScreenTools.scaleWidth
            color: "#FF6B6B"
            radius: 10
            
            Text {
                anchors.centerIn: parent
                text: "⚠️ 低液位警告 - 需要返航加水"
                font.pixelSize: 20 * ScreenTools.scaleWidth
                font.bold: true
                color: "white"
            }
        }
        
        contentItem: Column {
            spacing: 20 * ScreenTools.scaleWidth
            padding: 20 * ScreenTools.scaleWidth
            
            // 警告信息
            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: warningText.height + 30 * ScreenTools.scaleWidth
                color: "#2A3B4A"
                radius: 8
                border.color: "#FFA726"
                border.width: 1
                
                Column {
                    id: warningText
                    anchors.centerIn: parent
                    spacing: 10 * ScreenTools.scaleWidth
                    
                    Text {
                        text: "🚨 水箱液位过低!"
                        font.pixelSize: 18 * ScreenTools.scaleWidth
                        font.bold: true
                        color: "#FFA726"
                    }
                    
                    Text {
                        text: "剩余容积: " + Math.max(0, waterField.tankVolume - currentTotalVolume).toFixed(2) + " L"
                        font.pixelSize: 16 * ScreenTools.scaleWidth
                        color: "#FF6B6B"
                    }
                    
                    Text {
                        text: "水箱容量: " + waterField.tankVolume.toFixed(2) + " L"
                        font.pixelSize: 14 * ScreenTools.scaleWidth
                        color: "white"
                    }
                }
            }
            
            // 航点信息 - 显示保存的航点序号
            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: waypointInfo.height + 30 * ScreenTools.scaleWidth
                color: "#2A3B4A"
                radius: 8
                border.color: "#2EE59D"
                border.width: 1
                
                Column {
                    id: waypointInfo
                    anchors.centerIn: parent
                    spacing: 8 * ScreenTools.scaleWidth
                    
                    Text {
                        text: savedMissionWaypointIndex >= 0 ? "📍 已记录当前航点序号" : "📍 航点序号未记录"
                        font.pixelSize: 16 * ScreenTools.scaleWidth
                        font.bold: true
                        color: "#2EE59D"
                    }
                    
                    Text {
                        visible: savedMissionWaypointIndex >= 0
                        text: savedMissionWaypointIndex >= 0 ? "航点索引: " + savedMissionWaypointIndex : ""
                        font.pixelSize: 13 * ScreenTools.scaleWidth
                        color: "#B0BEC5"
                    }
                    
                    Text {
                        visible: activeVehicle && activeVehicle.missionCurrent && savedMissionWaypointIndex >= 0
                        text: (activeVehicle && activeVehicle.missionCurrent) ? ("总航点数: " + activeVehicle.missionCurrent.missionTotalItems) : ""
                        font.pixelSize: 13 * ScreenTools.scaleWidth
                        color: "#B0BEC5"
                    }
                }
            }
            
            // 返航信息
            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: returnInfo.height + 20 * ScreenTools.scaleWidth
                color: "#2A3B4A"
                radius: 8
                
                Column {
                    id: returnInfo
                    anchors.centerIn: parent
                    spacing: 8 * ScreenTools.scaleWidth
                    
                    Text {
                        text: "🏠 返航模式: 直线返航"
                        font.pixelSize: 14 * ScreenTools.scaleWidth
                        color: "#00E5FF"
                    }
                    
                    Text {
                        text: "📝 返航完成加水后,可返回此位置继续作业"
                        font.pixelSize: 13 * ScreenTools.scaleWidth
                        color: "#B0BEC5"
                        wrapMode: Text.WordWrap
                        width: parent.width - 20 * ScreenTools.scaleWidth
                    }
                }
            }
            
            // 按钮区域
            Row {
                spacing: 25 * ScreenTools.scaleWidth
                anchors.horizontalCenter: parent.horizontalCenter
                
                Button {
                    text: "❌ 取消返航"
                    width: 180 * ScreenTools.scaleWidth
                    height: 60 * ScreenTools.scaleWidth 
                    font.pixelSize: 18 * ScreenTools.scaleWidth 
                    font.bold: true
                    
                    background: Rectangle {
                        radius: 10 * ScreenTools.scaleWidth
                        color: parent.pressed ? "#D32F2F" : "#FF6B6B"
                        border.color: "#FFCDD2"
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
                        lowWaterDialog.close()
                    }
                }
                
                Button {
                    text: "✅ 确认返航"
                    width: 180 * ScreenTools.scaleWidth 
                    height: 60 * ScreenTools.scaleWidth 
                    font.pixelSize: 18 * ScreenTools.scaleWidth 
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
                        isReturningForRefill = true
                        
                        // 执行返航到Home点（通常是起飞点/加水点）
                        if (activeVehicle) {
                            // returnMission(wpid, execMode)
                            // wpid: NaN表示忽略航点，直接返航
                            // execMode: 0=直线返航, 1=沿航线正序返航, 2=沿航线逆序返航
                            activeVehicle.returnMission(NaN, 0)  // 直线返航到Home点
                            console.log("✈️ 返航命令已发送 - 模式: 直线返航")
                        }
                        
                        lowWaterDialog.close()
                        // 显示返航状态提示
                        returnStatusNotification.open()
                    }
                }
            }
        }
        
        onClosed: {
            // 对话框关闭时的处理
            if (!isReturningForRefill) {
                console.log("ℹ️ 低液位对话框已关闭,未执行返航")
            }
        }
    }

    // ================== 返航状态通知 ==================
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
                    // 根据状态显示不同的文本
                    text: isReturningToWork ? "✈️ 正在返回工作点..." : "🚁 正在返航加水..."
                    font.pixelSize: 16 * ScreenTools.scaleWidth
                    font.bold: true
                    color: "#2EE59D"
                }
            }
            
            Text {
                // 根据状态显示不同的提示
                text: isReturningToWork ? "即将到达工作点,继续作业" : "返航点已记录,加水完成后可返回"
                font.pixelSize: 13 * ScreenTools.scaleWidth
                color: "#B0BEC5"
            }
            
            Row {
                spacing: 12 * ScreenTools.scaleWidth
                anchors.horizontalCenter: parent.horizontalCenter
                
                // 只在返航加水时显示"返回工作点"按钮
                Button {
                    visible: !isReturningToWork  // 返回工作点时隐藏此按钮
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
                            console.log("✈️ 点击返回工作点按钮 - 打开二次确认")
                            returnToWorkConfirmDialog.open()
                        }
                    }
                }
                
                // 只在返回工作点时显示"已完成"按钮
                Button {
                    visible: isReturningToWork  // 只在返回工作点时显示
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
                        console.log("✅ 用户确认已完成返回工作点任务")
                        
                        // 重置所有状态
                        isReturningToWork = false
                        isReturningForRefill = false
                        lowWaterLevelDetected = false
                        hasShownLowWaterDialog = false
                        savedMissionWaypointIndex = -1  // 重置保存的航点索引
                        
                        // 关闭对话框
                        returnStatusNotification.close()
                        
                        console.log("🎉 任务完成，所有状态已重置")
                    }
                }
                
                // 关闭按钮 - 始终显示，不打断返航
                Button {
                    text: "关闭"
                    width: 100 * ScreenTools.scaleWidth
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
                    
                    onClicked: {
                        console.log("ℹ️ 关闭返航状态通知（返航继续进行）")
                        returnStatusNotification.close()
                    }
                }
            }
        }
    }
    
    // ================== 返回工作点二次确认对话框 ==================
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
            
            // 工作点坐标信息
            Rectangle {
                width: parent.width - 40 * ScreenTools.scaleWidth
                height: workPointInfo.height + 20 * ScreenTools.scaleWidth
                color: "#2A3B4A"
                radius: 8
                
                Column {
                    id: workPointInfo
                    anchors.centerIn: parent
                    spacing: 5 * ScreenTools.scaleWidth
                    
                    Text {
                        visible: savedMissionWaypointIndex >= 0
                        text: savedMissionWaypointIndex >= 0 ? "工作航点序号: " + savedMissionWaypointIndex : "航点索引未保存"
                        font.pixelSize: 14 * ScreenTools.scaleWidth
                        color: "#00E5FF"
                    }
                    
                    Text {
                        visible: activeVehicle && activeVehicle.missionCurrent && savedMissionWaypointIndex >= 0
                        text: (activeVehicle && activeVehicle.missionCurrent) ? ("任务总航点数: " + activeVehicle.missionCurrent.missionTotalItems) : ""
                        font.pixelSize: 13 * ScreenTools.scaleWidth
                        color: "#B0BEC5"
                    }
                }
            }
            
            Text {
                text: "确认已完成加水,准备返回工作点继续作业"
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
                    
                    onClicked: {
                        console.log("❌ 取消返回工作点")
                        returnToWorkConfirmDialog.close()
                    }
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
                            console.log("🔙 确认返回工作点(航点索引):", savedMissionWaypointIndex)
                            
                            // 设置返回工作点状态
                            isReturningToWork = true
                            isReturningForRefill = false  // 清除返航加水状态
                            
                            // 调用SDK的startMission接口，从保存的航点序号继续执行任务
                            if (activeVehicle) {
                                // startMission(wpid, execMode, doneAct)
                                // wpid: 起始航点序号 (从保存的航点索引开始)
                                // execMode: 0=顺序执行, 1=顺序执行但略过动作, 等
                                // doneAct: 0=悬停, 1=返航, 2=降落, 等
                                activeVehicle.startMission(savedMissionWaypointIndex, 0, 0)
                                console.log("✈️ 从航点", savedMissionWaypointIndex, "继续执行任务")
                            } else {
                                console.log("⚠️ 测试模式: 无飞机连接,仅模拟返回工作点")
                            }
                            
                            // 关闭确认对话框
                            returnToWorkConfirmDialog.close()
                        } else {
                            console.log("❌ 错误: 没有保存的航点索引")
                            returnToWorkConfirmDialog.close()
                        }
                    }
                }
            }
        }
    }
}
