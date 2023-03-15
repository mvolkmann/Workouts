import HealthKit

struct ChartKey: Hashable {
    let metric: HKQuantityTypeIdentifier
    let timeSpan: TimeSpan
}

struct ChartValue {
    let frequency: Frequency // of data collection
    let type: ChartType // bar or line
}

class ChartDetail {
    static let shared = ChartDetail()

    private var map: [ChartKey: ChartValue] = [:]

    private init() {
        addDetail(.activeEnergyBurned, .day, .hour, .line)
        addDetail(.activeEnergyBurned, .week, .day, .bar)
        addDetail(.activeEnergyBurned, .month, .day, .bar)
        addDetail(.activeEnergyBurned, .quarter, .week, .line)
        // TODO: Add more metric-specific details here?
    }

    private func addDetail(
        _ metric: HKQuantityTypeIdentifier,
        _ timeSpan: TimeSpan,
        _ frequency: Frequency,
        _ type: ChartType
    ) {
        let key = ChartKey(metric: metric, timeSpan: timeSpan)
        let value = ChartValue(frequency: frequency, type: type)
        map[key] = value
    }

    func frequency(
        metric: HKQuantityTypeIdentifier,
        timeSpan: TimeSpan
    ) -> Frequency? {
        let key = ChartKey(metric: metric, timeSpan: timeSpan)
        if let value = map[key] {
            return value.frequency
        } else {
            return timeSpan == .day ? .hour :
                timeSpan == .quarter ? .week :
                .day
        }
    }

    func type(
        metric: HKQuantityTypeIdentifier,
        timeSpan: TimeSpan
    ) -> ChartType? {
        let key = ChartKey(metric: metric, timeSpan: timeSpan)
        if let value = map[key] {
            return value.type
        } else {
            return timeSpan == .day || timeSpan == .quarter ? .line : .bar
        }
    }
}
