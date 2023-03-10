import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var loading = true
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

    private func round(_ n: Double) -> Int { Int(n.rounded()) }

    private func labelledValue(_ label: String, _ value: Double) -> some View {
        HStack {
            Text("\(label):")
            Spacer()
            Text(String(format: "%.0f", value))
                .fontWeight(.bold)
        }
    }

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

            // This is for testing the ability to examine individual samples.
            let manager = HealthKitManager()
            let endDate = Date.now
            let startDate = Calendar.current.date(
                byAdding: DateComponents(day: -2),
                to: endDate,
                wrappingComponents: false
            )!
            let n = try? await manager.samples(
                identifier: .distanceWalkingRunning,
                unit: .mile(),
                startDate: startDate,
                endDate: endDate
            )
        }
    }
}
