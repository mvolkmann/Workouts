import Combine // for onReceive method
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
                // If there are multiple decimal separators ...
                if newValue.count(of: decimalSeparator) > 1 {
                    // Remove the last decimal separator.
                    let character = decimalSeparator.first!
                    let index = newValue.lastIndex(of: character)
                    if let index {
                        var filtered = newValue // makes a copy
                        filtered.remove(at: index)
                        self.text = filtered
                    }
                } else {
                    // Remove all characters that are not allowed.
                    // We can't just check the last character
                    // because the user can insert characters anywhere.
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
