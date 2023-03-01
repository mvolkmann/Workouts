import SwiftUI

struct Workout: View {
    enum Field {
        case caloriesBurned, cyclingMiles
    }

    @AppStorage("defaultCalories") private var defaultCalories = "850"
    @AppStorage("defaultDuration") private var defaultDuration = "60"
    @AppStorage("defaultDistance") private var defaultDistance = "20"
    @AppStorage("defaultWorkoutType") private var defaultWorkoutType = "Cycling"
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) var scenePhase

    @State private var calories = ""
    @State private var date = Date.now
    @State private var distance = ""
    @State private var endTime = Date.now // adjusted in init
    @State private var isShowingAlert = false
    @State private var message = ""
    @State private var startTime = Date.now // adjusted in init
    @State private var workoutType = ""

    private var isFocused: FocusState<Bool>.Binding
    private let textFieldWidth: CGFloat = 110

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused

        // We can't just call resetDateAndTimes here because in the initializer
        // we need to create new State objects for endTime and startTime.
        let newEndTime = date.removeSeconds()
        _endTime = State(initialValue: newEndTime)
        let newStartTime = newEndTime.minutesBefore(Int(defaultDuration) ?? 0)
        _startTime = State(initialValue: newStartTime)
    }

    private func addWorkout() {
        Task {
            do {
                // HealthKit seems to round down to the nearest tenth.
                // For example, 20.39 becomes 20.3.
                // Adding 0.05 causes it to round to the nearest tenth.
                let distanceNumber = (distance as NSString).doubleValue + 0.05
                // Need to convert Int32 to Int.
                let caloriesNumber = Int((calories as NSString).intValue)

                try await HealthKitManager().addWorkout(
                    workoutType: workoutType,
                    startTime: startTime,
                    endTime: endTime,
                    distance: distanceNumber,
                    calories: caloriesNumber
                )

                // Reset the UI.
                distance = defaultDistance
                calories = defaultCalories
                message = "A \(workoutType) workout was added."
                isShowingAlert = true
            } catch {
                message = "Error adding workout: \(error)"
                isShowingAlert = true
            }
        }
    }

    private var canAdd: Bool {
        !distance.isEmpty && !calories.isEmpty
    }

    // TODO: Improve this before you start using it!
    private func computedCalories() -> Int {
        let calendar = Calendar.current
        let minutes = calendar.dateComponents(
            [.minute],
            from: startTime,
            to: endTime
        ).minute!

        let weight = 75.0 // kilograms
        let met = 11.0 // metabolic equivalent
        let caloriesPerMinute = met * weight * 3.5 / 200.0
        return Int(caloriesPerMinute * Double(minutes))
    }

    private func resetDateAndTimes() {
        date = Date.now
        endTime = date.removeSeconds()
        startTime = endTime.minutesBefore(Int(defaultDuration) ?? 0)
    }

    var body: some View {
        ZStack {
            let fill = gradient(.orange, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()
            VStack(spacing: 10) {
                if !workoutType.isEmpty {
                    WorkoutTypePicker(workoutType: $workoutType)
                }

                DatePicker(
                    "Date",
                    selection: $date,
                    displayedComponents: .date
                )

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
                    Spacer()
                    Button(action: resetDateAndTimes) {
                        Image(systemName: "arrow.clockwise")
                    }
                }

                if distanceWorkouts.contains(workoutType) {
                    HStack {
                        Text("\(preferKilometers ? "Kilometers" : "Miles")")
                        Spacer()
                        TextField("", text: $distance)
                            .focused(isFocused)
                            .numbersOnly($distance, float: true)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: textFieldWidth)
                    }
                }

                HStack {
                    Text("Calories Burned")
                    /*
                     Button("Compute") {
                     caloriesBurned = String(computedCalories())
                     }
                     */
                    Spacer()
                    TextField("", text: $calories)
                        .focused(isFocused)
                        .numbersOnly($calories)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: textFieldWidth)
                }

                Button("Add Workout") {
                    addWorkout()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdd)
            }
            .font(.title2)
            .fontWeight(.bold)
            .padding()
        }

        .alert(
            "Success",
            isPresented: $isShowingAlert,
            actions: {},
            message: { Text(message) }
        )

        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing

            // Can't do this in init.
            workoutType = defaultWorkoutType
            calories = defaultCalories
            distance = defaultDistance
        }

        .onChange(of: defaultCalories) { _ in
            calories = defaultCalories
        }

        .onChange(of: defaultDuration) { _ in
            if let minutes = Int(defaultDuration) {
                startTime = endTime.minutesBefore(minutes)
            }
        }

        .onChange(of: defaultDistance) { _ in
            distance = defaultDistance
        }

        .onChange(of: scenePhase) { [scenePhase] newPhase in
            if scenePhase == .background, newPhase == .inactive {
                resetDateAndTimes()
            }
        }
    }
}
