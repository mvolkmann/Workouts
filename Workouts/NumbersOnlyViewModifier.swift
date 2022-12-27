import Combine
import SwiftUI

// See the Stewart Lynch video at
// https://www.youtube.com/watch?v=dd079CQ4Fr4&t=2s.
struct NumbersOnlyViewModifier: ViewModifier {
    @Binding var text: String
    var float: Bool

    func body(content: Content) -> some View {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let allowed = "0123456789" + (float ? decimalSeparator : "")

        content
            // Using a keyboardType of .decimalPad or .numberPad is not enough
            // to prevent other keys from being pressed because those keyboards
            // contain more keys when running on an iPad.
            .keyboardType(float ? .decimalPad : .numberPad)
            .onReceive(Just(text)) { newValue in
                if newValue.count(of: decimalSeparator) > 1 {
                    let filtered = newValue
                    self.text = String(filtered.dropLast())
                } else {
                    // Only keep allowed characters.
                    // TODO: Can we only check the last character?
                    let filtered = newValue.filter { allowed.contains($0) }
                    if filtered != newValue {
                        self.text = filtered
                    }
                }
            }
    }
}

extension String {
    func count(of string: String) -> Int {
        let char = string.first!
        return reduce(0) { $1 == char ? $0 + 1 : $0 }
    }
}

extension View {
    func numbersOnly(
        _ text: Binding<String>,
        float: Bool = false
    ) -> some View {
        modifier(NumbersOnlyViewModifier(text: text, float: float))
    }
}
