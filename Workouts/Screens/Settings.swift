import SwiftUI

struct Settings: View {
    @AppStorage("defaultCalories") private var defaultCalories = "850"
    @AppStorage("defaultDuration") private var defaultDuration = "60"
    @AppStorage("defaultDistance") private var defaultDistance = "20"
    @AppStorage("defaultWorkoutType") private var defaultWorkoutType = "Cycling"
    @AppStorage("preferKilometers") private var preferKilometers = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var isFocused: FocusState<Bool>.Binding
    private let textFieldWidth: CGFloat = 110

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused

        // This changes the font used by the segmented Picker below.
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 20, weight: .bold)],
            for: .normal
        )
    }

    var body: some View {
        ZStack {
            let fill = gradient(.red, colorScheme: colorScheme)
            Rectangle().fill(fill).ignoresSafeArea()

            VStack(spacing: 20) {
                WorkoutTypePicker(workoutType: $defaultWorkoutType)

                Picker("", selection: $preferKilometers) {
                    Text("Miles").tag(false)
                    Text("Kilometers").tag(true)
                }
                .pickerStyle(.segmented)

                DurationPicker(duration: $defaultDuration)

                if distanceWorkouts.contains(defaultWorkoutType) {
                    LabeledContent("Distance") {
                        TextField("distance", text: $defaultDistance)
                            .focused(isFocused)
                            .numbersOnly($defaultDistance, float: true)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: textFieldWidth)
                    }
                }

                LabeledContent("Calories") {
                    TextField("calories", text: $defaultCalories)
                        .focused(isFocused)
                        .numbersOnly($defaultDistance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: textFieldWidth)
                }
            }
            .font(.title2)
            .fontWeight(.bold)
            .padding()
        }
    }
}
