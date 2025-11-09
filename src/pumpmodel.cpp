#include "pumpmodel.h"
#include <qdebug.h>

PumpModel::PumpModel(QObject *parent)
    : QObject(parent),
      m_flowRate(0.0),
      m_totalVolume(0.0)
// ✅ 【删除】m_remainingVolume(0.0)
{ }

double PumpModel::flowRate() const {
     qDebug() << "flowRate() getter被调用，返回值:" << m_flowRate;
    return m_flowRate; }
void PumpModel::setFlowRate(double rate)
{
    // if (m_flowRate != rate) {
        m_flowRate = rate;
        emit flowRateChanged();
    // }
}

double PumpModel::totalVolume() const { return m_totalVolume; }
void PumpModel::setTotalVolume(double volume)
{
    if (m_totalVolume != volume) {
        m_totalVolume = volume;
        emit totalVolumeChanged();
    }
}

// ✅ 【删除】以下三个方法：
// double PumpModel::remainingVolume() const { return m_remainingVolume; }
// void PumpModel::setRemainingVolume(double volume)
// {
//     if (m_remainingVolume != volume) {
//         m_remainingVolume = volume;
//         emit remainingVolumeChanged();
//     }
// }
