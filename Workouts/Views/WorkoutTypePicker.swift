import HealthKit
import SwiftUI

let activityMap: [String: HKWorkoutActivityType] = [
    "Boxing": .boxing,
    "Climbing": .climbing,
    "Cycling": .cycling,
    "Elliptical": .elliptical,
    "Hiking": .hiking,
    "Kickboxing": .kickboxing,
    "Pilates": .pilates,
    "Rowing": .rowing,
    "Running": .running,
    "Skating Sports": .skatingSports,
    "Stairs": .stairs,
    "Swimming": .swimming,
    "Yoga": .yoga,
    "Walking": .walking
]

struct WorkoutTypePicker: View {
    let types: [String] = Array(activityMap.keys).sorted()

    var workoutType: Binding<String>

    var body: some View {
        LabeledContent("Workout Type") {
            // Wrapping the Picker in a Menu allows us to control the font used.
            Menu {
                Picker("", selection: workoutType) {
                    ForEach(types, id: \.self) { type in
                        Text(type)
                    }
                }
            } label: {
                Text(workoutType.wrappedValue + " ")
                    .font(.title2)
                    .foregroundColor(.primary) +
                    Text(Image(systemName: "chevron.down"))
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
}
