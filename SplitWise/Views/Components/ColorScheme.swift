import SwiftUI

// MARK: - N26 Dark Theme Colors 🌙

extension Color {
    // N26 Hauptfarben
    static let n26Background = Color(hex: "1A1A1A")        // Fast Schwarz
    static let n26CardBackground = Color(hex: "262626")    // Dunkelgrau für Karten
    static let n26CardBackgroundLight = Color(hex: "333333") // Etwas heller
    static let n26Teal = Color(hex: "36A18B")              // N26 Türkis (Akzent)
    static let n26TealLight = Color(hex: "4ECBB5")         // Helleres Türkis
    static let n26TextPrimary = Color.white
    static let n26TextSecondary = Color(hex: "8A8A8A")     // Grauer Text
    static let n26TextMuted = Color(hex: "666666")         // Noch grauer
    static let n26Success = Color(hex: "4CAF50")           // Grün für positive Beträge
    static let n26Error = Color(hex: "FF6B6B")             // Rot für negative Beträge
    static let n26Warning = Color(hex: "FFB74D")           // Orange für Warnungen
    static let n26Divider = Color(hex: "333333")           // Trennlinien

    // Bier-Theme Farben 🍺
    static let beerGold = Color(hex: "F4A825")             // Goldenes Bier
    static let beerAmber = Color(hex: "D97706")            // Bernstein
    static let beerFoam = Color(hex: "FEF3C7")             // Schaum
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - N26 Card Style

struct N26CardStyle: ViewModifier {
    var highlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .padding()
            .background(highlighted ? Color.n26CardBackgroundLight : Color.n26CardBackground)
            .cornerRadius(16)
    }
}

extension View {
    func n26Card(highlighted: Bool = false) -> some View {
        modifier(N26CardStyle(highlighted: highlighted))
    }
}

// MARK: - N26 Button Style

struct N26ButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(isPrimary ? .black : .n26Teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isPrimary ? Color.n26Teal : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : Color.n26Teal, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Beer Pattern Background 🍺

struct BeerPatternBackground: View {
    var body: some View {
        ZStack {
            Color.n26Background

            VStack(spacing: 100) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 80) {
                        ForEach(0..<4, id: \.self) { col in
                            Text(["🍺", "🍻", "🥂", "🍾"][(row + col) % 4])
                                .font(.system(size: 40))
                                .opacity(0.035)
                                .rotationEffect(.degrees(Double((row + col) * 8 - 15)))
                        }
                    }
                    .offset(x: row % 2 == 0 ? 40 : -40)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Amount Text Style

extension View {
    func amountStyle(isPositive: Bool) -> some View {
        self
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(isPositive ? .n26Success : .n26Error)
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color = .n26Teal, radius: CGFloat = 8) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Participant Avatar View

struct ParticipantAvatarView: View {
    let participant: Participant
    let size: CGFloat

    init(participant: Participant, size: CGFloat = 44) {
        self.participant = participant
        self.size = size
    }

    var body: some View {
        Group {
            if let imageData = participant.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(participant.avatarEmoji)
                    .font(.system(size: size * 0.5))
            }
        }
        .frame(width: size, height: size)
        .background(Color.n26CardBackgroundLight)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.n26Teal.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Section Header Style

struct N26SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Text(icon)
            }
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.n26TextSecondary)
                .textCase(.uppercase)
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}
