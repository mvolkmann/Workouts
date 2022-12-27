import SwiftUI

struct ContentView: View {
    enum Field {
        case caloriesBurned, cyclingMiles
    }

    static let defaultCyclingMiles = "20.0"
    static let defaultCaloriesBurned = "850" // for one hour

    @FocusState private var focusedField: Field?

    @State private var caloriesBurned = Self.defaultCaloriesBurned
    @State private var cyclingMiles = Self.defaultCyclingMiles
    @State private var endTime = Date() // adjusted in init
    @State private var isShowingAlert = false
    @State private var message = ""
    @State private var startTime = Date() // adjusted in init

    @StateObject private var viewModel = HealthKitViewModel()

    init() {
        // Remove seconds from the end time.
        let calendar = Calendar.current
        let endSeconds = calendar.component(.second, from: endTime)
        let secondsCleared = calendar.date(
            byAdding: .second,
            value: -endSeconds,
            to: endTime
        )!
        _endTime = State(initialValue: secondsCleared)

        // Set start time to one hour before the end time.
        let oneHourBefore = calendar.date(
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
                let calories = (caloriesBurned as NSString).intValue
                try await HealthKitManager().addCyclingWorkout(
                    startTime: startTime,
                    endTime: endTime,
                    distance: distance,
                    calories: Int(calories)
                )
                cyclingMiles = Self.defaultCyclingMiles
                caloriesBurned = Self.defaultCaloriesBurned
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
            cyclingWorkout
        }
        .padding()
        .alert(
            "Success",
            isPresented: $isShowingAlert,
            actions: {},
            message: { Text(message) }
        )
        // This enables dismissing the keyboard which is
        // displayed when a TextField has focus.
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
