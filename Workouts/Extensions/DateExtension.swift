import Foundation

extension Date {
    func minutesBefore(_ minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .minute,
            value: -minutes,
            to: self
        )!
    }

    var startOfYear: Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(
            from: DateComponents(year: year, month: 1, day: 1)
        )!
    }
}
