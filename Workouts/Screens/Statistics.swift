import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var loading = true
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

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.accentColor)
            .padding(.bottom, 10)
    }

    var body: some View {
        ZStack {
            let fill = gradient(.yellow, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()
            VStack {
                if !loading {
                    title("Since Start of Year")
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

                    Divider()

                    title("Over Last 7 Days")
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
            }
            .font(.headline)
            .padding()
        }
        .task {
            loading = true
            await vm.load()
            loading = false
        }
    }
}
