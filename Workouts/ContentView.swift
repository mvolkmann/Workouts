import SwiftUI

struct ContentView: View {
    enum Field {
        case cyclingMiles
    }

    @FocusState private var focusedField: Field?
    @State private var cyclingMiles = ""
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

            Text("Cycling Workout")
                .font(.title)
                .padding(.top)
            HStack {
                TextField("Miles", text: $cyclingMiles)
                    .focused($focusedField, equals: .cyclingMiles)
                    .numbersOnly($cyclingMiles, float: true)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    HealthKitManager().addKeiserWorkout(distance: 20)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button {
                    focusedField = nil
                } label: {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
