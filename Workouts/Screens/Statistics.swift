import Charts
import HealthKit
import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject private var errorVM: ErrorViewModel

    @State private var loading = true
    @State private var samples: [HKQuantitySample] = []
    @State private var statsKind = "year"

    @StateObject private var vm = HealthKitViewModel()

    private var distanceWalkingRunning: Int {
        let miles = vm.distanceWalkingRunning
        guard preferKilometers else { return round(miles) }
        return round(
            Measurement(value: miles, unit: UnitLength.miles)
                .converted(to: UnitLength.kilometers).value
        )
    }

    private func loadSamples(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async {
        do {
            samples = try await weekSamples(identifier: identifier, unit: unit)
        } catch {
            samples = []
            errorVM.alert(
                error: error,
                message: "Error loading HealthKit samples."
            )
        }
    }

    private var healthChart: some View {
        print("heartRate data =", vm.heartRate)
        return Chart {
            /*
             ForEach(vm.heartRate, id: \.self) { data in
             LineMark(
             x: .value("Date", data.),
             y: .value("Value", value)
             )
             .interpolationMethod(interpolationMethod)
             }
             */
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

    private func round(_ n: Double) -> Int { Int(n.rounded()) }

    private var statsForWeek: some View {
        VStack(alignment: .leading) {
            labelledValue("Heart Rate Average", vm.heartRate)
            labelledValue(
                "Resting Heart Rate Average",
                vm.restingHeartRate
            )
            labelledValue("Steps per day", vm.steps / 7)
            let active = vm.activeEnergyBurned / 7
            labelledValue("Active Calories burned per day", active)
            let basal = vm.basalEnergyBurned / 7
            labelledValue("Basal Calories burned per day", basal)
            labelledValue(
                "Total Calories burned per day",
                active + basal
            )
        }
    }

    private var statsForYear: some View {
        VStack(alignment: .leading) {
            if vm.distanceSwimming > 0 {
                labelledValue(
                    "Swimming Distance",
                    vm.distanceSwimming
                )
            }
            if vm.distanceCycling > 0 {
                labelledValue(
                    "Cycling Distance",
                    vm.distanceCycling
                )
            }
            if vm.distanceWalkingRunning > 0 {
                labelledValue(
                    "Walk+Run Distance",
                    vm.distanceWalkingRunning
                )
            }
        }
    }

    private func weekSamples(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> [HKQuantitySample] {
        let manager = HealthKitManager()
        let endDate = Date.now
        let startDate = Calendar.current.date(
            byAdding: DateComponents(day: -7),
            to: endDate,
            wrappingComponents: false // TODO: Why needed?
        )!
        let samples = try await manager.samples(
            identifier: identifier,
            unit: unit,
            startDate: startDate,
            endDate: endDate
        )
        return samples
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
            await vm.load()
            loading = false

            // let unit = HKUnit.mile()
            let unit = HKUnit(from: "count/min")
            await loadSamples(identifier: .heartRate, unit: unit)
            if let sample = samples.first {
                print("Statistics: startDate =", sample.startDate)
                print("Statistics: endDate =", sample.endDate)
                let bpm = sample.quantity.doubleValue(for: unit)
                print("Statistics: bpm =", bpm)
            }
            // TODO: Use this data in healthChart above.
        }
    }
}
