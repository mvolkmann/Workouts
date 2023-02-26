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
                    labelledValue("Average Heart Rate", viewModel.heartRate)
                    labelledValue(
                        "Average Resting Heart Rate",
                        viewModel.restingHeartRate
                    )
                    labelledValue("Steps", viewModel.steps)
                    labelledValue(
                        "Calories Burned",
                        viewModel.activeEnergyBurned
                    )
                }
            }
            .font(.title2)
            .fontWeight(.bold)
            .padding()
        }
    }
}
