#include "tcpclient.h"
#include <QDebug>
#include <cstring>
#include <QTimer> // 添加超时处理需要的头文件

MyTcpClient::MyTcpClient(PumpModel *model, QObject *parent)
    : QObject(parent),
      m_socket(new QTcpSocket(this)),
      m_pumpModel(model),
      m_connected(false),
      m_connecting(false)
{
    connect(m_socket, &QTcpSocket::connected, this, &MyTcpClient::onConnected);
    connect(m_socket, &QTcpSocket::disconnected, this, &MyTcpClient::onDisconnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &MyTcpClient::onReadyRead);
    connect(m_socket, QOverload<QAbstractSocket::SocketError>::of(&QTcpSocket::errorOccurred),
            this, &MyTcpClient::onErrorOccurred);
    connect(m_socket, &QTcpSocket::stateChanged, this, &MyTcpClient::onStateChanged);

    // 初始化缓冲区 - 保持不变
    flow_buffer[0] = 0xAA;
    flow_buffer[1] = 0;
    flow_buffer[2] = 1;
    flow_buffer[3] = 0;

    flow_buffer[4] = 0xFF;
}

void MyTcpClient::connectToHost(const QString &ip, quint16 port)
{
    if (m_connecting) {
        qDebug() << "Already connecting, please wait...";
        return;
    }

    if (m_socket->isOpen()) {
        m_socket->close();
    }

    m_connecting = true;
    m_lastError.clear();

    emit connectingChanged(m_connecting);
    emit lastErrorChanged(m_lastError);

    qDebug() << "Connecting to" << ip << ":" << port;
    m_socket->connectToHost(ip, port);

    // 设置连接超时
    QTimer::singleShot(5000, this, [this]() {
        if (m_connecting && !m_connected) {
            m_lastError = "Connection timeout";
            m_connecting = false;
            emit connectingChanged(m_connecting);
            emit lastErrorChanged(m_lastError);
            m_socket->abort();
            qDebug() << "Connection timeout";
        }
    });
}

void MyTcpClient::disconnectFromHost()
{
    if (m_socket->state() != QAbstractSocket::UnconnectedState) {
        m_socket->disconnectFromHost();
        if (m_socket->state() == QAbstractSocket::ConnectedState) {
            m_socket->waitForDisconnected(1000);
        }
    }
}

void MyTcpClient::sendMessage(const QString &message)
{
    // 保持原有的发送逻辑不变
    if (m_socket->state() == QAbstractSocket::ConnectedState) {
        bool conversionSuccessful;

               // 将 QString 转换为 int
        int value = message.toInt(&conversionSuccessful);

        if (conversionSuccessful) {
            // 转换成功，进一步转换为 uint8_t
            uint8_t uint8Value = static_cast<uint8_t>(value);
            std::memcpy(&flow_buffer[1], &uint8Value, sizeof(uint8_t));

            // 输出结果
            qDebug() << "Converted value as uint8_t:" << static_cast<int>(uint8Value);
        } else {
            // 转换失败
            qDebug() << "Conversion failed. Invalid input:" << message;
        }

        flow_buffer[0] = 0XAA;
        flow_buffer[4] = 0XFF;
        m_socket->write(flow_buffer, sizeof(flow_buffer));
        m_socket->flush();
    } else {
        qDebug() << "Socket is not connected. Cannot send message.";
    }
}

void MyTcpClient::send_init_pump(const char &message)
{
                                                        // 保持原有的发送逻辑不变
    if (m_socket->state() == QAbstractSocket::ConnectedState) {

        std::memcpy(&flow_buffer[3], &message, sizeof(char));

               // 输出结果
        //     qDebug() << "Converted value as uint8_t:" << static_cast<int>(uint8Value);
        // } else {
        //     // 转换失败
        //     qDebug() << "Conversion failed. Invalid input:" << message;
        // }

        flow_buffer[0] = 0XAA;
        flow_buffer[4] = 0XFF;
        m_socket->write(flow_buffer, sizeof(flow_buffer));
        m_socket->flush();
    } else {
        qDebug() << "Socket is not connected. Cannot send message.";
    }
}

void MyTcpClient::send_isopen_pump(const char &message)
{
    // 保持原有的发送逻辑不变
      if (m_socket->state() == QAbstractSocket::ConnectedState) {
    //     bool conversionSuccessful;

    //            // 将 QString 转换为 int
    //     int value = message.toInt(&conversionSuccessful);

    //     if (conversionSuccessful) {
    //         // 转换成功，进一步转换为 uint8_t
    //         uint8_t uint8Value = static_cast<uint8_t>(value);
            std::memcpy(&flow_buffer[2], &message, sizeof(char));

                   // 输出结果
        //     qDebug() << "Converted value as uint8_t:" << static_cast<int>(uint8Value);
        // } else {
        //     // 转换失败
        //     qDebug() << "Conversion failed. Invalid input:" << message;
        // }

        flow_buffer[0] = 0XAA;
            flow_buffer[3] = 0;
        flow_buffer[4] = 0XFF;
        m_socket->write(flow_buffer, sizeof(flow_buffer));
        m_socket->flush();
    } else {
        qDebug() << "Socket is not connected. Cannot send message.";
    }
}

void MyTcpClient::onConnected()
{
    qDebug() << "Connected to server.";
    m_connected = true;
    m_connecting = false;
    m_lastError.clear();

    emit connectedChanged(m_connected);
    emit connectingChanged(m_connecting);
    emit lastErrorChanged(m_lastError);
    emit connected(); // 原有的信号
}

void MyTcpClient::onDisconnected()
{
    qDebug() << "Disconnected from server.";
    m_connected = false;
    m_connecting = false;

    emit connectedChanged(m_connected);
    emit connectingChanged(m_connecting);
    emit disconnected(); // 原有的信号
}

void MyTcpClient::onStateChanged(QAbstractSocket::SocketState state)
{
    qDebug() << "Socket state changed to:" << state;

    // 如果连接失败，确保状态正确
    if (state == QAbstractSocket::UnconnectedState && (m_connected || m_connecting)) {
        m_connected = false;
        m_connecting = false;
        emit connectedChanged(m_connected);
        emit connectingChanged(m_connecting);
    }
}

void MyTcpClient::onReadyRead()
{
    // 保持原有的数据解析逻辑不变
    QByteArray data = m_socket->readAll();

           // 确保数据长度至少为 10 字节
    while (data.size() >= 10) {
        // 查找帧头
        int headerIndex = data.indexOf('\xAA');
        if (headerIndex == -1) {
            // 如果没有找到帧头，移除已处理的数据
            data.remove(0, 1);
            continue; // 继续下一个循环
        }

               // 检查是否有足够的数据以获取完整的数据帧
        if (data.size() < headerIndex + 10) {
            break; // 不足够，等待更多数据
        }

               // 检查帧尾
        if (data[headerIndex + 9] != '\xFF') {
            data.remove(0, headerIndex + 1); // 移除无效数据
            continue;
        }

               // 提取完整的数据帧
        QByteArray frame = data.mid(headerIndex, 10);
        data.remove(0, headerIndex + 10); // 移除已处理的数据帧

               // 解析流速和总量（假设为 4 字节 float）
        float flowRate, totalVolume;

        // 方法1：使用 memcpy 避免对齐问题
        std::memcpy(&flowRate, frame.data() + 1, sizeof(float));
        std::memcpy(&totalVolume, frame.data() + 5, sizeof(float));

        // 如果需要字节序转换（假设网络字节序是大端）
        // flowRate = qFromBigEndian<float>(flowRate);
        // totalVolume = qFromBigEndian<float>(totalVolume);

               // 转换为 double 存储
        m_pumpModel->setFlowRate(static_cast<double>(flowRate));
        m_pumpModel->setTotalVolume(static_cast<double>(totalVolume));

        qDebug() << "Flow Rate:" << flowRate
                 << ", Total Volume:" << totalVolume;
    }
}

void MyTcpClient::onErrorOccurred(QAbstractSocket::SocketError error)
{
    Q_UNUSED(error)
    m_lastError = m_socket->errorString();
    m_connected = false;
    m_connecting = false;

    qDebug() << "Socket Error:" << m_lastError;

    emit connectedChanged(m_connected);
    emit connectingChanged(m_connecting);
    emit lastErrorChanged(m_lastError);
    emit errorOccurred(m_lastError);
}
