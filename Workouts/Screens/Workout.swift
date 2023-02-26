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

    @FocusState private var focusedField: Field?

    @State private var calories = ""
    @State private var date = Date()
    @State private var distance = ""
    @State private var endTime = Date() // adjusted in init
    @State private var isShowingAlert = false
    @State private var message = ""
    @State private var startTime = Date() // adjusted in init
    @State private var workoutType = ""

    private let gradient = LinearGradient(
        colors: [.orange, .white],
        startPoint: .top,
        endPoint: .bottom
    )

    init() {
        // TODO: Move most of this code DateExtension.
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
                focusedField = nil
                message = "A cycling workout was added."
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

    var body: some View {
        ZStack {
            Rectangle().fill(gradient).ignoresSafeArea()
            VStack {
                /*
                 Text("Add a Workout")
                     .font(.title)
                     .fontWeight(.bold)
                 */

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
                    Text("Cycling Miles")
                    Spacer()
                    TextField("", text: $distance)
                        .focused($focusedField, equals: .cyclingMiles)
                        .numbersOnly($distance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
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
                        .focused($focusedField, equals: .caloriesBurned)
                        .numbersOnly($calories)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
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
