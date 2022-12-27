import SwiftUI

struct ContentView: View {
    enum Field {
        case caloriesBurned, cyclingMiles
    }

    @FocusState private var focusedField: Field?
    @State private var caloriesBurned = "850" // default for one hour
    @State private var cyclingMiles = ""
    @State private var isShowingAlert = false
    @State private var message = ""
    @StateObject private var viewModel = HealthKitViewModel()

    private func addWorkout() {
        Task {
            do {
                // HealthKit seems to round down to the nearest tenth.
                // For example, 20.39 becomes 20.3.
                // Adding 0.05 causes it to round to the nearest tenth.
                let distance = (cyclingMiles as NSString).doubleValue + 0.05
                print("distance =", distance)
                let calories = (caloriesBurned as NSString).doubleValue
                try await HealthKitManager().addCyclingWorkout(
                    distance: distance,
                    calories: calories
                )
                cyclingMiles = ""
                focusedField = nil
                message = "A cycling workout was added."
                isShowingAlert = true
            } catch {
                message = "Error adding workout: \(error)"
                isShowingAlert = true
            }
        }
    }

    private func labelledValue(_ label: String, _ value: Double) -> some View {
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
            VStack {
                TextField("Cycling Miles", text: $cyclingMiles)
                    .focused($focusedField, equals: .cyclingMiles)
                    .numbersOnly($cyclingMiles, float: true)
                    .textFieldStyle(.roundedBorder)
                TextField("Calories Burned", text: $caloriesBurned)
                    .focused($focusedField, equals: .caloriesBurned)
                    .numbersOnly($caloriesBurned)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addWorkout()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .alert(
            "Success",
            isPresented: $isShowingAlert,
            actions: {},
            message: { Text(message) }
        )

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
