import SwiftUI

struct LargeBlueMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(AppTheme.Colors.softBlue)
                .bold()
            
            Text(value)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.softBlue)
            }
        }
        .padding(AppTheme.Radii.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.primaryBlue)
        .cornerRadius(AppTheme.Radii.large)
    }
}
