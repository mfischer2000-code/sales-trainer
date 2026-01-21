import SwiftUI

/// App-weite Farbdefinitionen
extension Color {
    static let appPrimary = Color.blue
    static let appSecondary = Color.purple
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appDanger = Color.red

    static let cardBackground = Color(.systemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
}

/// Custom Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool

    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? Color.gray : Color.appPrimary)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Card Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
