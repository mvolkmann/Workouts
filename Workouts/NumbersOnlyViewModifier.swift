import Combine
import SwiftUI

// See the Stewart Lynch video at
// https://www.youtube.com/watch?v=dd079CQ4Fr4&t=2s.
struct NumbersOnlyViewModifier: ViewModifier {
    @Binding var text: String
    var float: Bool

    func body(content: Content) -> some View {
        var allowed = "0123456789"
        content
            .keyboardType(float ? .decimalPad : .numberPad)
            .onReceive(Just(text)) { newValue in
                let decimalSeparator = Locale.current.decimalSeparator ?? "."
                if float { allowed += decimalSeparator }
                // If we already have a decimal separator, don't allow another.
                if newValue.contains(decimalSeparator) {
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

extension View {
    func numbersOnly(
        _ text: Binding<String>,
        float: Bool = false
    ) -> some View {
        modifier(NumbersOnlyViewModifier(text: text, float: float))
    }
}
