import SwiftUI

struct ContentView: View {
    enum Field {
        case caloriesBurned, cyclingMiles
    }

    @FocusState private var focusedField: Field?
    @State private var caloriesBurned = "850" // default for one hour
    @State private var cyclingMiles = "20.0"
    @State private var endTime = Date()
    @State private var startTime = Date()
    @State private var isShowingAlert = false
    @State private var message = ""
    @StateObject private var viewModel = HealthKitViewModel()

    init() {
        let oneHourBefore = Calendar.current.date(
            byAdding: .hour,
            value: -1,
            to: endTime
        )!
        _startTime = State(initialValue: oneHourBefore)
    }

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
                    startTime: startTime,
                    endTime: endTime,
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

    private var cyclingWorkout: some View {
        Form {
            Text("Cycling Workout")
                .font(.title)
                .padding(.top)
            DatePicker(
                "Start Time",
                selection: $startTime,
                displayedComponents: .hourAndMinute
            )
            DatePicker(
                "End Time",
                selection: $endTime,
                displayedComponents: .hourAndMinute
            )
            HStack {
                Text("Cycling Miles")
                Spacer()
                TextField("", text: $cyclingMiles)
                    .focused($focusedField, equals: .cyclingMiles)
                    .numbersOnly($cyclingMiles, float: true)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 90)
            }
            HStack {
                Text("Calories Burned")
                Spacer()
                TextField("", text: $caloriesBurned)
                    .focused($focusedField, equals: .caloriesBurned)
                    .numbersOnly($caloriesBurned)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 90)
            }
            Button("Add") {
                addWorkout()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var healthStatistics: some View {
        VStack {
            Text("Health Statistics\nfor the Past 7 Days")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            VStack(alignment: .leading) {
                labelledValue("Average Heart Rate", viewModel.heartRate)
                labelledValue(
                    "Average Resting Heart Rate",
                    viewModel.restingHeartRate
                )
                labelledValue("Total Steps", viewModel.steps)
                labelledValue(
                    "Total Calories Burned",
                    viewModel.activeEnergyBurned
                )
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
        .frame(maxWidth: 270)
    }

    var body: some View {
        VStack {
            healthStatistics

            Spacer()

            cyclingWorkout
        }
        .padding()
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
