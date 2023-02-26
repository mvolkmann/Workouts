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

    private var isFocused: FocusState<Bool>.Binding

    init(isFocused: FocusState<Bool>.Binding) {
        self.isFocused = isFocused

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
                WorkoutTypePicker(workoutType: $defaultWorkoutType)

                Picker("", selection: $preferKilometers) {
                    Text("Miles").tag(false)
                    Text("Kilometers").tag(true)
                }
                .pickerStyle(.segmented)

                DurationPicker(duration: $defaultDuration)

                LabeledContent("Distance") {
                    TextField("distance", text: $defaultDistance)
                        .focused(isFocused)
                        .numbersOnly($defaultDistance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
                }

                LabeledContent("Calories") {
                    TextField("calories", text: $defaultCalories)
                        .focused(isFocused)
                        .numbersOnly($defaultDistance, float: true)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 90)
                }
            }
            .font(.title2)
            .fontWeight(.bold)
            .padding()
        }
    }
}
