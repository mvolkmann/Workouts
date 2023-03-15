import HealthKit

struct ChartDetail {
    let metric: HKQuantityTypeIdentifier
    let timeSpan: TimeSpan
    let frequency: Frequency
    let type: ChartType
}
