import HealthKit

enum ChartType {
    case bar, line
}

struct ChartInfo {
    let title: String
    let type: ChartType
    // let identifier: HKQuantityTypeIdentifier
    // let interval: DateComponents
    // let unit: HKUnit
    // let options: HKStatisticsOptions
    let data: [DatedValue]
    let startDate: Date
    let endDate: Date
}
