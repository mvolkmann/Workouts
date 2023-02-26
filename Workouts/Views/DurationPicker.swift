import SwiftUI

struct DurationPicker: View {
    var duration: Binding<String>

    let options = Array(stride(from: 5, to: 360, by: 5))

    var body: some View {
        LabeledContent("Duration (minutes)") {
            // Wrapping the Picker in a Menu allows us to control the font used.
            Menu {
                Picker("", selection: duration) {
                    ForEach(options, id: \.self) { minutes in
                        Text("\(minutes)").tag("\(minutes)")
                    }
                }
            } label: {
                Text(duration.wrappedValue + " ")
                    .font(.title2)
                    .foregroundColor(.primary) +
                    Text(Image(systemName: "chevron.down"))
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
    }
}
