import SwiftUI

struct Settings: View {
    enum Field {
        case miles, calories
    }

    @AppStorage("defaultCalories") private var defaultCalories = "850"
    @AppStorage("defaultDuration") private var defaultDuration = "60"
    @AppStorage("defaultDistance") private var defaultDistance = "20"
    @AppStorage("defaultWorkoutType") private var defaultWorkoutType = "Cycling"
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedField: Field?

    init() {
        // This changes the font used by the segmented Picker below.
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 20, weight: .bold)],
            for: .normal
        )
    }

    private let gradient = LinearGradient(
        colors: [.red, .white],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            Rectangle().fill(gradient).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Default Settings")
                    .accessibilityIdentifier("settings-title")
                    .font(.title)
                    .fontWeight(.bold)
                    .onTapGesture { dismiss() }

                WorkoutTypePicker(workoutType: $defaultWorkoutType)

                Picker("", selection: $preferKilometers) {
                    Text("Miles").tag(false)
                    Text("Kilometers").tag(true)
                }
                .pickerStyle(.segmented)

                DurationPicker(duration: $defaultDuration)

                LabeledContent("Distance") {
                    TextField("distance", text: $defaultDistance)
                        .focused($focusedField, equals: .miles)
                        .numbersOnly($defaultDistance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
                }

                LabeledContent("Calories") {
                    TextField("calories", text: $defaultCalories)
                        .focused($focusedField, equals: .calories)
                        .numbersOnly($defaultDistance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
                }

                Spacer()
            }
            .font(.title2)
            .fontWeight(.bold)
            .padding()
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
