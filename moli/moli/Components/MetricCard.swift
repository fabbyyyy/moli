import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(AppTheme.Colors.mutedGray)
                    .bold()
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: AppTheme.Shadows.card.x, y: AppTheme.Shadows.card.y)
    }
}
