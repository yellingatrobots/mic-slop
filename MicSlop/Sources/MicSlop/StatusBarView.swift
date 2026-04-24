import SwiftUI

struct StatusBarView: View {
    let isOnAir: Bool
    
    var body: some View {
        Text(isOnAir ? "ON AIR" : "OFF AIR")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isOnAir ? Color(red: 1.0, green: 0.231, blue: 0.188) : Color(white: 0.557))
            .cornerRadius(3)
    }
}

// Preview only works in Xcode, not with SPM command-line builds
#if DEBUG && canImport(PreviewsMacros)
#Preview {
    VStack(spacing: 10) {
        StatusBarView(isOnAir: true)
        StatusBarView(isOnAir: false)
    }
    .padding()
}
#endif
