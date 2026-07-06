import SwiftUI

/// Creep's identity: a deep-teal/mustard-yellow grocery-receipt palette —
/// evokes register tape and pantry labels. Distinct from every sibling
/// app's colors (no rust/asphalt, no cobalt/lime, no cream/sage reused).
enum CRTheme {
    static let backdrop = Color(red: 0.925, green: 0.949, blue: 0.941)   // pale mint-paper
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.882, green: 0.914, blue: 0.902)
    static let ink = Color(red: 0.098, green: 0.196, blue: 0.176)        // deep teal-ink
    static let inkFaded = Color(red: 0.098, green: 0.196, blue: 0.176).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let teal = Color(red: 0.086, green: 0.412, blue: 0.365)      // deep teal
    static let mustard = Color(red: 0.831, green: 0.643, blue: 0.098)   // mustard-yellow accent
    static let mustardBright = Color(red: 0.914, green: 0.729, blue: 0.176)
    static let danger = Color(red: 0.702, green: 0.243, blue: 0.204)
    static let success = Color(red: 0.176, green: 0.451, blue: 0.302)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
