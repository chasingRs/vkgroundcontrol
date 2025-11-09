#ifndef PUMPMODEL_H
#define PUMPMODEL_H

#include <QObject>

class PumpModel : public QObject {
    Q_OBJECT
    Q_PROPERTY(double flowRate READ flowRate WRITE setFlowRate NOTIFY flowRateChanged)
    Q_PROPERTY(double totalVolume READ totalVolume WRITE setTotalVolume NOTIFY totalVolumeChanged)

public:
    explicit PumpModel(QObject *parent = nullptr);

    double flowRate() const;
    void setFlowRate(double rate);

    double totalVolume() const;
    void setTotalVolume(double volume);

           // 添加Q_INVOKABLE方法
    Q_INVOKABLE double getFlowRateValue() const { return m_flowRate; }
    Q_INVOKABLE double getTotalVolumeValue() const { return m_totalVolume; }

signals:
    void flowRateChanged();
    void totalVolumeChanged();

private:
    double m_flowRate;
    double m_totalVolume;
};

#endif // PUMPMODEL_H
