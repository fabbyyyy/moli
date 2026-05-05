import SwiftUI

struct InsightCard: View {
    let insight: AIInsight
    
    var colorForInsight: Color {
        switch insight.type {
        case .expired: return AppTheme.Colors.dangerRed
        case .expiringSoon: return AppTheme.Colors.alertOrange
        case .gap: return AppTheme.Colors.mutedGray
        case .trend, .rotation: return AppTheme.Colors.primaryBlue
        case .warning: return AppTheme.Colors.alertYellow
        }
    }
    
    var iconForInsight: String {
        switch insight.type {
        case .trend, .rotation: return "chart.line.uptrend.xyaxis"
        default: return "circle.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(colorForInsight.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if insight.type == .trend || insight.type == .rotation {
                    Image(systemName: iconForInsight)
                        .foregroundColor(colorForInsight)
                        .font(.system(size: 16, weight: .bold))
                } else {
                    Circle()
                        .fill(colorForInsight)
                        .frame(width: 12, height: 12)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.mutedGray)
            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: AppTheme.Shadows.card.x, y: AppTheme.Shadows.card.y)
    }
}
