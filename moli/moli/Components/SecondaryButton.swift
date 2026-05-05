import SwiftUI

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.Colors.softBlue)
            .foregroundColor(AppTheme.Colors.primaryBlue)
            .cornerRadius(AppTheme.Radii.medium)
        }
        .accessibilityLabel(title)
    }
}
