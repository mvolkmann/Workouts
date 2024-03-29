import Charts
import HealthKit
import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var chartType: ChartType = .line
    @State private var data: [DatedValue] = []
    @State private var dateToValueMap: [String: Double] = [:]
    @State private var metric = Metrics.shared.map[.heartRate]!
    @State private var runningMiles = 0.0
    @State private var selectedDate = ""
    @State private var selectedValue = 0.0
    @State private var statsKind = "year"
    // @State private var statsKind = "chart"
    @State private var timeSpan: TimeSpan = .week

    @StateObject private var vm = HealthKitViewModel.shared

    private let unitMap: [HKUnit: String] = [
        .count(): "count",
        HKUnit(from: "count/min"): "beats per minute",
        HKUnit(from: "ft/s"): "feet per second",
        .hour(): "hours",
        .largeCalorie(): "calories",
        HKUnit(from: "m/s"): "meters per second",
        .inch(): "inches",
        .meter(): "meters",
        .mile(): "miles",
        HKUnit.secondUnit(with: .milli): "standard deviation in milliseconds",
        .minute(): "minutes",
        .percent(): "percentage",
        .pound(): "pounds"
    ]

    private func animateChart() {
        for index in data.indices {
            // Delay rendering each data point a bit longer than the previous one.
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index) * 0.015
            ) {
                let spring = 0.5
                withAnimation(.interactiveSpring(
                    response: spring,
                    dampingFraction: spring,
                    blendDuration: spring
                )) {
                    if index < data.count {
                        data[index].animate = true
                    }
                }
            }
        }
    }

    private var annotation: some View {
        VStack {
            Text(dateDisplay)
            Text(formattedValue)
        }
        .padding(5)
        .background {
            let fillColor: Color = colorScheme == .light ?
                .white : Color(.secondarySystemBackground)
            let myFill = fillColor.shadow(.drop(radius: 3))
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(myFill)
        }
        .foregroundColor(Color(.label))
    }

    private func annotationPosition(_ index: Int) -> AnnotationPosition {
        let percent = Double(index) / Double(data.count)
        return percent < 0.1 ? .topTrailing :
            percent > 0.95 ? .topLeading :
            .top
    }

    private func canScaleYAxis(metric: Metric) -> Bool {
        if chartType == .bar { return false }

        if metric.unit == .percent() { return false }

        // If the percent difference between the min and max values is very small,
        // setting the y-axis to only go from min to max causes the app to crash.
        let min = minValue
        let percentDifference = (maxValue - min) / min
        return percentDifference >= 0.1
    }

    private var chart: some View {
        Chart {
            // ForEach(data, id: \.self) { dataPoint in
            ForEach(data.indices, id: \.self) { index in
                let datedValue = data[index]

                let multiplier = metric.unit == .percent() ? 100.0 : 1.0
                let value = datedValue.animate ?
                    datedValue.value * multiplier : 0.0

                if chartType == .line {
                    LineMark(
                        x: .value("Date", datedValue.date),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)

                    // if !canScaleYAxis(metric: metric) {
                    AreaMark(
                        x: .value("Date", datedValue.date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    // }
                } else {
                    BarMark(
                        x: .value("Date", datedValue.date),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)
                }

                if datedValue.date == selectedDate {
                    RuleMark(x: .value("Date", selectedDate))
                        .annotation(
                            position: annotationPosition(index)
                        ) {
                            annotation
                        }
                        .foregroundStyle(.red)
                        .lineStyle(.init(
                            lineWidth: 1,
                            dash: [10],
                            dashPhase: 5
                        ))
                }
            }
        }

        .frame(height: 300)

        // Leave room for RuleMark annotations.
        .padding(.horizontal, 20)
        .padding(.top, 55)

        .onAppear { animateChart() }

        .chartLegend(.hidden)

        // Support tapping on the plot area to see data point details.
        .chartOverlay { proxy in chartOverlay(proxy: proxy) }

        // Hide the x-axis and its labels.
        // TODO: Can you only hide the labels?
        .chartXAxis(.hidden)

        .if(canScaleYAxis(metric: metric)) { view in
            view
                // Change the y-axis to begin at minValue and end at maxValue.
                // This causes a crash for some metrics.
                .chartYScale(domain: minValue ... maxValue)

                // Stop AreaMarks from spilling outside chart.
                .clipShape(Rectangle())
        }

        // Give the plot area a background color.
        .chartPlotStyle { content in
            content.background(Color(.secondarySystemBackground))
        }
    }

    private func chartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { _ in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let location = value.location
                            if let date: String = proxy.value(atX: location.x) {
                                selectedDate = date
                                selectedValue = dateToValueMap[date] ?? 0.0
                            }
                        }
                        .onEnded { _ in selectedDate = "" }
                )
        }
    }

    private var chartTypePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Chart Type").fontWeight(.bold)
            Picker("", selection: $chartType) {
                ForEach(ChartType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: chartType) { _ in
            // Make a copy of data where "animate" is false in each item.
            // This allows the new chart to be animated.
            data = data.map { item in
                DatedValue(
                    date: item.date,
                    ms: item.ms,
                    unit: item.unit,
                    value: item.value
                )
            }

            animateChart()
        }
    }

    private var dateDisplay: String {
        if timeSpan == .day { return selectedDate }
        let parts = selectedDate.components(separatedBy: " ")
        return parts.first ?? selectedDate
    }

    private var distanceWalkingRunning: Int {
        let miles = vm.distanceWalkingRunning.reduce(0) { $0 + $1.value }
        guard preferKilometers else { return round(miles) }
        return round(
            Measurement(value: miles, unit: UnitLength.miles)
                .converted(to: UnitLength.kilometers).value
        )
    }

    private var formattedValue: String {
        let intUnits: [HKUnit] = [.count(), .largeCalorie()]
        if intUnits.contains(metric.unit) {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let value = Int(selectedValue)
            return numberFormatter.string(from: NSNumber(value: value))!
        }

        let format = "%.\(sd(metric.decimalPlaces))f"
        let isPercent = metric.unit == .percent()
        let value = isPercent ? selectedValue * 100 : selectedValue
        return String(format: format, value) + (isPercent ? "%" : "")
    }

    private var healthChart: some View {
        VStack {
            metricPicker
            timeSpanPicker
            chartTypePicker

            Text(title).fontWeight(.bold)
            Text(metricName)
            // Text("values go from \(minValue) to \(maxValue)")
            if data.count == 0 {
                Text(
                    "No data was found for this metric and time span. " +
                        "Perhaps you did not grant access to all health data."
                )
                .padding(.top)
            } else {
                chart
            }
        }
    }

    private func labelledValue(_ label: String, _ value: Double) -> some View {
        HStack {
            Text("\(label):")
            Spacer()
            Text(String(format: "%.0f", value))
                .fontWeight(.bold)
        }
    }

    private func loadData() {
        let detail = ChartDetail.shared

        chartType = detail.type(
            metric: metric.identifier,
            timeSpan: timeSpan
        ) ?? .bar

        let frequency = detail.frequency(
            metric: metric.identifier,
            timeSpan: timeSpan
        )

        Task {
            do {
                let newData = try await HealthStore().getData(
                    identifier: metric.identifier,
                    startDate: startDate,
                    frequency: frequency
                ) { data in
                    metric.option == .cumulativeSum ?
                        data.sumQuantity() :
                        data.averageQuantity()
                }
                // All objects in data will now have "animate" set to false.

                dateToValueMap = [:]
                for item in newData {
                    dateToValueMap[item.date] = item.value
                }

                data = newData
                animateChart()
            } catch {
                errorVM.alert(
                    error: error,
                    message: "Error loading health data."
                )
            }
        }
    }

    private func loadRunningMiles() {
        runningMiles = 0.0

        let store = HKHealthStore()

        let endDate = Date.now
        let workoutDate = HKQuery.predicateForWorkoutActivities(
            start: endDate.startOfYear,
            end: endDate
        )

        let workouts = HKQuery.predicateForWorkouts(
            activityPredicate: workoutDate
        )

        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: workouts,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if let error {
                errorVM.alert(
                    error: error,
                    message: "Error loading health data."
                )
                return
            }

            guard let workouts = samples as? [HKWorkout] else { return }

            var miles = 0.0
            for workout in workouts {
                if workout.workoutActivityType == .running {
                    let quantityType = HKQuantityType(.distanceWalkingRunning)
                    let distance = workout.statistics(for: quantityType)?
                        .sumQuantity()
                    if let distance {
                        miles += distance.doubleValue(for: .mile())
                    }
                }
            }

            runningMiles = miles
        }

        store.execute(query)
    }

    private var maxValue: Double {
        let item = data.max { $0.value < $1.value }
        return item?.value ?? 0.0
    }

    private var metricName: String {
        if metric.identifier == .respiratoryRate {
            return "breaths per minute"
        }
        return unitMap[metric.unit] ?? metric.unit.unitString
    }

    private var metricPicker: some View {
        HStack {
            Text("Metric").fontWeight(.bold)
            Picker("", selection: $metric) {
                ForEach(Metrics.shared.sorted) {
                    Text($0.name).tag($0)
                }
            }
            Spacer()
        }
        .onChange(of: metric) { _ in loadData() }
    }

    private var minValue: Double {
        let item = data.min { $0.value < $1.value }
        return item?.value ?? 0.0
    }

    private func round(_ n: Double) -> Int { Int(n.rounded()) }

    private var startDate: Date {
        let today = Date().withoutTime
        return timeSpan == .day ? today.yesterday :
            timeSpan == .week ? today.daysBefore(7) :
            timeSpan == .month ? today.monthsBefore(1) :
            timeSpan == .quarter ? today.monthsBefore(3) :
            // For .headphoneAudioExposure I could get data for 25 days,
            // but asking for any more crashes the app with the error
            // "Unable to invalidate interval: no data source available".
            // I had a small amount of data from Apple Watch.
            // I couldn't view the data from iPhone ... maybe too much.
            // After deleting all of that data from the Health app,
            // I can now view that metric with "1 Month" selected.
            today
    }

    private var statsForWeek: some View {
        VStack(alignment: .leading, spacing: 20) {
            labelledValue("Heart Rate Average", vm.heartRateAverage)
            labelledValue(
                "Resting Heart Rate Average",
                vm.restingHeartRateAverage
            )
            labelledValue("Steps per day", vm.stepSum / 7)
            let active = vm.activeEnergyBurnedSum / 7
            labelledValue("Active Calories burned per day", active)
            let basal = vm.basalEnergyBurnedSum / 7
            labelledValue("Basal Calories burned per day", basal)
            labelledValue(
                "Total Calories burned per day",
                active + basal
            )
        }
        .font(.headline)
        .padding(.top)
    }

    private var statsForYear: some View {
        VStack(alignment: .leading) {
            if vm.distanceSwimmingSum > 0 {
                labelledValue(
                    "Swimming Distance",
                    vm.distanceSwimmingSum
                )
            }
            if vm.distanceCyclingSum > 0 {
                labelledValue(
                    "Cycling Miles",
                    vm.distanceCyclingSum
                )
            }
            if runningMiles > 0 {
                labelledValue("Running Miles", runningMiles)
            }
            if vm.distanceWalkingRunningSum > 0 {
                labelledValue(
                    "Walk+Run Miles",
                    vm.distanceWalkingRunningSum
                )
            }
        }
        .font(.title)
    }

    private var timeSpanPicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Time Span").fontWeight(.bold)
            Picker("", selection: $timeSpan) {
                ForEach(TimeSpan.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: timeSpan) { _ in loadData() }
    }

    private var title: String {
        if metric.identifier == .bodyMass { return "Weight" }
        if metric.identifier == .vo2Max { return "VO2 Max" }

        var text = metric.identifier.rawValue

        // Remove metric prefix.
        let prefix = "HKQuantityTypeIdentifier"
        if text.starts(with: prefix) {
            text = text[prefix.count...]
        }

        // Add a space before all uppercase characters except the first.
        var result = text[0]
        for char in text.dropFirst() {
            if char.isUppercase { result += " " }
            result.append(char)
        }

        return result
    }

    var body: some View {
        ZStack {
            let fill = gradient(.yellow, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()
            VStack {
                Picker("", selection: $statsKind) {
                    Text(String(Date.now.year)).tag("year")
                    Text("Past 7 Days").tag("week")
                    Text("Charts").tag("charts")
                }
                .pickerStyle(.segmented)

                switch statsKind {
                case "year":
                    statsForYear
                case "week":
                    statsForWeek
                case "charts":
                    healthChart
                default:
                    EmptyView()
                }

                Spacer()
            }
            .padding()
        }
        .task {
            loadRunningMiles()
            loadData()

            do {
                try await vm.load()
            } catch {
                errorVM.alert(
                    error: error,
                    message: "Error loading health data."
                )
            }
        }
    }
}
