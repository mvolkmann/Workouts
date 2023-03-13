import Charts
import HealthKit
import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var chartType = "Line"
    @State private var data: [DatedValue] = []
    @State private var dateToValueMap: [String: Double] = [:]
    @State private var frequency: Frequency = .day
    @State private var metric = Metrics.shared.map[.heartRate]!
    @State private var statsKind = "year"
    @State private var timeSpan = "1 Week"

    @StateObject private var vm = HealthKitViewModel.shared

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
                    data[index].animate = true
                }
            }
        }
    }

    private var chartTypePicker: some View {
        picker(
            label: "Chart Type",
            values: ["Bar", "Line"],
            selected: $chartType
        )
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

    private var distanceWalkingRunning: Int {
        let miles = vm.distanceWalkingRunning.reduce(0) { $0 + $1.value }
        guard preferKilometers else { return round(miles) }
        return round(
            Measurement(value: miles, unit: UnitLength.miles)
                .converted(to: UnitLength.kilometers).value
        )
    }

    private var healthChart: some View {
        VStack {
            metricPicker
            timeSpanPicker
            chartTypePicker

            Chart {
                // ForEach(data, id: \.self) { dataPoint in
                ForEach(data.indices, id: \.self) { index in
                    let datedValue = data[index]

                    if chartType == "Line" {
                        LineMark(
                            x: .value("Date", datedValue.date),
                            y: .value("Value", datedValue.value)
                        )
                        .interpolationMethod(.catmullRom)
                    } else {
                        BarMark(
                            x: .value("Date", datedValue.date),
                            y: .value("Value", datedValue.value)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
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
        print("\(#fileID) \(#function) entered")
        Task {
            do {
                let newData = try await HealthStore().getData(
                    identifier: metric.identifier,
                    startDate: startDate,
                    frequency: frequency
                ) { data in
                    print("\(#fileID) \(#function) data =", data)
                    return metric.option == .cumulativeSum ?
                        data.sumQuantity() :
                        data.averageQuantity()
                }
                // All objects in data will now have "animate" set to false.

                print("\(#fileID) \(#function) newData =", newData)
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

    private func picker(
        label: String,
        values: [String],
        selected: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).fontWeight(.bold)
            Picker("", selection: selected) {
                ForEach(values, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func round(_ n: Double) -> Int { Int(n.rounded()) }

    private var startDate: Date {
        let today = Date().withoutTime
        return timeSpan == "1 Day" ? today.yesterday :
            timeSpan == "1 Week" ? today.daysBefore(7) :
            timeSpan == "1 Month" ? today.monthsBefore(1) :
            timeSpan == "3 Months" ? today.monthsBefore(3) :
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
        VStack(alignment: .leading) {
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
                    "Cycling Distance",
                    vm.distanceCyclingSum
                )
            }
            if vm.distanceWalkingRunningSum > 0 {
                labelledValue(
                    "Walk+Run Distance",
                    vm.distanceWalkingRunningSum
                )
            }
        }
    }

    private var timeSpanPicker: some View {
        picker(
            label: "Time Span",
            values: ["1 Day", "1 Week", "1 Month", "3 Months"],
            selected: $timeSpan
        )
        .onChange(of: timeSpan) { _ in
            switch timeSpan {
            case "1 Day":
                frequency = .hour
            case "1 Week":
                frequency = .day
            case "1 Month":
                frequency = .day
            case "3 Months":
                frequency = .week
            default:
                break
            }

            loadData()
        }
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
                    statsForYear.font(.title)
                case "week":
                    statsForWeek.font(.headline)
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
            await HealthStore().requestPermission()

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
