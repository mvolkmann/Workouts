import SwiftUI

func gradient(
    _ primaryColor: Color,
    colorScheme: ColorScheme
) -> LinearGradient {
    let secondaryColor: Color = colorScheme == .dark ? .black : .white
    return LinearGradient(
        colors: [primaryColor, secondaryColor],
        startPoint: .top,
        endPoint: .bottom
    )
}
