#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QTcpSocket>
#include <QObject>
#include "pumpmodel.h"



class MyTcpClient : public QObject
{
    Q_OBJECT

    // 添加 Q_PROPERTY 暴露连接状态给 QML
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool connecting READ isConnecting NOTIFY connectingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit MyTcpClient(PumpModel *model, QObject *parent = nullptr);

    // Q_INVOKABLE 方法供 QML 调用
    Q_INVOKABLE void connectToHost(const QString &ip, quint16 port);
    Q_INVOKABLE void disconnectFromHost();
    Q_INVOKABLE void sendMessage(const QString &message);
    Q_INVOKABLE void send_isopen_pump(const char &message);
    Q_INVOKABLE void send_init_pump(const char &message);

    // Getter 方法
    bool isConnected() const { return m_connected; }
    bool isConnecting() const { return m_connecting; }
    QString lastError() const { return m_lastError; }


signals:
    void connectedChanged(bool connected);
    void connectingChanged(bool connecting);
    void lastErrorChanged(const QString &error);
    void errorOccurred(const QString &error);
    void connected();    // 原有的信号
    void disconnected(); // 原有的信号

private slots:
    void onConnected();
    void onDisconnected();
    void onReadyRead();
    void onErrorOccurred(QAbstractSocket::SocketError error);
    void onStateChanged(QAbstractSocket::SocketState state);

private:
    QTcpSocket *m_socket;
    PumpModel *m_pumpModel;

    // 状态变量
    bool m_connected;
    bool m_connecting;
    QString m_lastError;

    char flow_buffer[5];

    // 发送缓冲区 - 保持不变
};

#endif // TCPCLIENT_H
