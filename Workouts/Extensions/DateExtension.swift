import Foundation

extension Date {
    func daysAfter(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .day,
            value: days,
            to: self
        )!
    }

    func daysBefore(_ days: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .day,
            value: -days,
            to: self
            // wrappingComponents: false // TODO: Need this?
        )!
    }

    func daysBetween(date: Date) -> Int {
        let components = Calendar.current.dateComponents(
            [.day],
            from: self,
            to: date
        )
        return components.day ?? Int.max // should always have a value for day
    }

    static func from(dateComponents: DateComponents) -> Date? {
        Calendar.current.date(from: dateComponents)
    }

    static func from(year: Int, month: Int, day: Int) -> Date? {
        // swiftlint:disable identifier_name
        var dc = DateComponents()
        dc.year = year
        dc.month = month
        dc.day = day
        return Date.from(dateComponents: dc)
    }

    static func from(ms: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(ms / 1000))
    }

    func hoursAfter(_ hours: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .hour,
            value: hours,
            to: self
        )!
    }

    func hoursBetween(date: Date) -> Int {
        let components = Calendar.current.dateComponents(
            [.hour],
            from: self,
            to: date
        )
        return components.hour ?? Int.max // should always have a value for hour
    }

    var milliseconds: Int {
        Int((timeIntervalSince1970 * 1000.0).rounded())
    }

    func minutesBefore(_ minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .minute,
            value: -minutes,
            to: self
        )!
    }

    static func mondayAt12AM() -> Date {
        Calendar(identifier: .iso8601)
            .date(from: Calendar(identifier: .iso8601).dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: Date()
            ))!
    }

    func monthsBefore(_ months: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            byAdding: .month,
            value: -months,
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

    var withoutTime: Date {
        let from = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: self
        )
        return Calendar.current.date(from: from)!
    }

    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    var yesterday: Date {
        let begin = withoutTime
        return Calendar.current.date(byAdding: .day, value: -1, to: begin)!
    }

    // Returns a String representation of the Date in "yyyy-mm-dd" format
    // with no time display.
    var ymd: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }

    // Returns a String representation of the Date in "yyyy-mm-dd" format
    // including hours and AM|PM.
    var ymdh: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h a"
        return dateFormatter.string(from: self)
    }
}
