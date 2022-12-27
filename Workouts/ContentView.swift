import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HealthKitViewModel()

    func labelledValue(_ label: String, _ value: Double) -> some View {
        Text("\(label): \(String(format: "%.0f", value))")
    }

    var body: some View {
        VStack {
            Text("Health Statistics for Past 7 Days")
                .font(.title)
            labelledValue("Average Heart Rate", viewModel.heartRate)
            labelledValue(
                "Average Resting Heart Rate",
                viewModel.restingHeartRate
            )
            labelledValue("Total Steps", viewModel.steps)
            labelledValue("Total Calories Burned", viewModel.activeEnergyBurned)

            Button("Add Keiser Workout") {
                HealthKitManager().addKeiserWorkout(distance: 20)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
