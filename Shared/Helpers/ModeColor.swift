import SwiftUI

enum ModeColor {

    /// Adaptive mode color — slightly darkened + saturated in dark mode.
    /// Already-dark colors (like Sleep) get lightened instead.
    static func adaptive(lightHex: String) -> Color {
        Color(uiColor: UIColor { traits in
            let base = UIColor(hexString: lightHex)
            guard traits.userInterfaceStyle == .dark else { return base }
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            if b < 0.35 {
                return UIColor(hue: h, saturation: s * 0.8, brightness: min(b * 1.5, 0.5), alpha: a)
            }
            return UIColor(hue: h, saturation: min(s * 1.3, 1.0), brightness: b * 0.75, alpha: a)
        })
    }

    /// Low-opacity fill for time block backgrounds.
    static func blockBackground(lightHex: String) -> Color {
        Color(uiColor: UIColor { traits in
            let base = UIColor(hexString: lightHex)
            return traits.userInterfaceStyle == .dark
                ? base.withAlphaComponent(0.2)
                : base.withAlphaComponent(0.15)
        })
    }

    /// Derived foreground color readable on the block background.
    static func blockForeground(lightHex: String) -> Color {
        Color(uiColor: UIColor { traits in
            let base = UIColor(hexString: lightHex)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            if traits.userInterfaceStyle == .dark {
                return UIColor(hue: h, saturation: s * 0.7, brightness: min(b * 1.25, 1.0), alpha: a)
            }
            return UIColor(hue: h, saturation: min(s * 1.5, 1.0), brightness: b * 0.6, alpha: a)
        })
    }
}
