import SwiftUI

struct Statistics: View {
    @AppStorage("preferKilometers") private var preferKilometers = false
    @StateObject private var viewModel = HealthKitViewModel()

    private let gradient = LinearGradient(
        colors: [.yellow, .white],
        startPoint: .top,
        endPoint: .bottom
    )

    private var distanceWalkingRunning: Int {
        let miles = viewModel.distanceWalkingRunning
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

    var body: some View {
        ZStack {
            Rectangle().fill(gradient).ignoresSafeArea()
            VStack {
                Text("Since Start of Year")
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    labelledValue(
                        "Walk+Run Distance",
                        viewModel.distanceWalkingRunning
                    )
                    labelledValue("Cycling Distance", viewModel.distanceCycling)
                }

                Divider()

                Text("Over Last 7 Days")
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 10)
                VStack(alignment: .leading) {
                    labelledValue("Heart Rate Average", viewModel.heartRate)
                    labelledValue(
                        "Resting Heart Rate Average",
                        viewModel.restingHeartRate
                    )
                    labelledValue("Steps per day", viewModel.steps / 7)
                    let active = viewModel.activeEnergyBurned / 7
                    labelledValue("Active Calories burned per day", active)
                    let basal = viewModel.basalEnergyBurned / 7
                    labelledValue("Basal Calories burned per day", basal)
                    labelledValue(
                        "Total Calories burned per day",
                        active + basal
                    )
                }
            }
            .font(.headline)
            .padding()
        }
    }
}
