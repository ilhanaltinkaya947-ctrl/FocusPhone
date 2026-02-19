import SwiftUI

enum FPTheme {

    // MARK: - Corner Radii

    static let cardRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12

    // MARK: - Spacing

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    // MARK: - Typography

    static let heroDateFont: Font = .system(size: 48, weight: .bold, design: .default)
    static let largeTitleFont: Font = .system(size: 28, weight: .bold, design: .default)
    static let sectionTitleFont: Font = .system(size: 17, weight: .semibold)
    static let bodyFont: Font = .system(size: 15, weight: .regular)
    static let captionFont: Font = .system(size: 13, weight: .regular)
    static let timelineHourFont: Font = .system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Semantic Colors

    static var backgroundPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                : UIColor(red: 0.976, green: 0.969, blue: 0.957, alpha: 1.0)
        })
    }

    static var backgroundSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
                : UIColor.white
        })
    }

    static var textPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
                : UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        })
    }

    static var textSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
                : UIColor(red: 0.45, green: 0.45, blue: 0.47, alpha: 1.0)
        })
    }

    static var divider: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
                : UIColor(red: 0.88, green: 0.87, blue: 0.85, alpha: 1.0)
        })
    }

    static let currentTimeIndicator = Color(hex: "#E8685A")
}
