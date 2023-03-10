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

    func removeSeconds() -> Date {
        let calendar = Calendar.current
        let seconds = calendar.component(.second, from: self)
        return calendar.date(
            byAdding: .second,
            value: -seconds,
            to: self
        )!
    }

    var startOfYear: Date {
        let year = Calendar.current.component(.year, from: Date())
        return Calendar.current.date(
            from: DateComponents(year: year, month: 1, day: 1)
        )!
    }

    var year: Int {
        Calendar.current.component(.year, from: self)
    }
}
