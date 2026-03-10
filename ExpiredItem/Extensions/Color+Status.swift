import SwiftUI

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - ItemStatus Colors & Gradients
extension ItemStatus {
    var color: Color {
        switch self {
        case .fresh: return Color(hex: "2ECC71")
        case .expiringSoon: return Color(hex: "F39C12")
        case .expired: return Color(hex: "E74C3C")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .fresh: return Color(hex: "2ECC71").opacity(0.12)
        case .expiringSoon: return Color(hex: "F39C12").opacity(0.12)
        case .expired: return Color(hex: "E74C3C").opacity(0.12)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .expired:
            return LinearGradient(
                colors: [Color(hex: "FF416C"), Color(hex: "FF4B2B")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .expiringSoon:
            return LinearGradient(
                colors: [Color(hex: "F7971E"), Color(hex: "FFD200")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .fresh:
            return LinearGradient(
                colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var glowColor: Color {
        switch self {
        case .expired: return Color(hex: "FF416C").opacity(0.45)
        case .expiringSoon: return Color(hex: "F7971E").opacity(0.45)
        case .fresh: return Color(hex: "11998e").opacity(0.45)
        }
    }
}

// MARK: - Category Colors
extension Category {
    var color: Color {
        switch self {
        case .produce: return Color(hex: "27AE60")
        case .dairy: return Color(hex: "3498DB")
        case .meat: return Color(hex: "E74C3C")
        case .bakery: return Color(hex: "E67E22")
        case .frozen: return Color(hex: "00B4DB")
        case .beverages: return Color(hex: "8E44AD")
        case .condiments: return Color(hex: "F1C40F")
        case .snacks: return Color(hex: "E91E8C")
        case .medicine: return Color(hex: "E74C3C")
        case .cosmetics: return Color(hex: "9B59B6")
        case .other: return Color(hex: "95A5A6")
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
