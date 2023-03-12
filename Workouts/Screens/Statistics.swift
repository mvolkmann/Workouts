import Charts
import HealthKit
import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var chartInfo: ChartInfo?
    @State private var data: [DatedValue] = []
    @State private var loading = true
    @State private var statsKind = "year"

    @StateObject private var vm = HealthKitViewModel.shared

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
            if let chartInfo {
                Text(chartInfo.title).font(.headline)
                Chart {
                    // ForEach(data, id: \.self) { dataPoint in
                    ForEach(data.indices, id: \.self) { index in
                        let datedValue = data[index]

                        switch chartInfo.type {
                        case .bar:
                            BarMark(
                                x: .value("Date", datedValue.date),
                                y: .value("Value", datedValue.value)
                            )
                            .interpolationMethod(.catmullRom)
                        case .line:
                            LineMark(
                                x: .value("Date", datedValue.date),
                                y: .value("Value", datedValue.value)
                            )
                            .interpolationMethod(.catmullRom)
                        }
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

    /*
     private func loadSamples(info: ChartInfo) async {
         do {
             let manager = HealthKitManager()
             /*
              statistics = try await manager.statistics(
                  identifier: info.identifier,
                  interval: info.interval,
                  unit: info.unit,
                  options: info.options,
                  startDate: info.startDate,
                  endDate: info.endDate
              )
              */
             data = manager.getData(
                 identifier: info.identifier,
                 startDate: info.startDate,
                 endDate: info.endDate,
                 frequency: info.frequency,
                 quantityFunction: info.quantityFunction
             )
         } catch {
             statistics = []
             errorVM.alert(
                 error: error,
                 message: "Error loading HealthKit samples."
             )
         }
     }
     */

    private func round(_ n: Double) -> Int { Int(n.rounded()) }

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

    var body: some View {
        ZStack {
            let fill = gradient(.yellow, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()
            if !loading {
                VStack {
                    Picker("", selection: $statsKind) {
                        Text(String(Date.now.year)).tag("year")
                        Text("Past 7 Days").tag("week")
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom)

                    if statsKind == "year" {
                        statsForYear
                            .font(.title)
                    } else {
                        healthChart
                        statsForWeek
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .task {
            loading = true
            defer {
                Task { @MainActor in loading = false }
            }

            do {
                // TODO: This code may need to move somewhere.
                try await vm.load()
            } catch {
                errorVM.alert(
                    error: error,
                    message: "Error getting health data."
                )
            }
        }
    }
}
