import SwiftUI

struct ProductRecommendationCard: View {
    @Binding var recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.product.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(recommendation.product.brand)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)
                }
                
                Spacer()
                
                // Stepper for quantity
                HStack(spacing: 12) {
                    Button(action: decrementQuantity) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(AppTheme.Colors.mutedGray)
                            .font(.title3)
                    }
                    
                    Text("\(recommendation.editableQuantity)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 30)
                        .multilineTextAlignment(.center)
                    
                    Button(action: incrementQuantity) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.Colors.primaryBlue)
                            .font(.title3)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(AppTheme.Colors.backgroundGray)
                .cornerRadius(AppTheme.Radii.extraLarge)
            }
            
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.mutedGray)
                .fixedSize(horizontal: false, vertical: true)
            
            if recommendation.suggestedQuantity != recommendation.editableQuantity {
                Text("Sugerencia original: \(recommendation.suggestedQuantity)")
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.alertOrange)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardWhite)
        .cornerRadius(AppTheme.Radii.medium)
        .shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: AppTheme.Shadows.card.x, y: AppTheme.Shadows.card.y)
    }
    
    private func decrementQuantity() {
        guard recommendation.editableQuantity > 0 else {
            return
        }
        
        recommendation.editableQuantity -= 1
        recommendation.status = .modified
    }
    
    private func incrementQuantity() {
        recommendation.editableQuantity += 1
        recommendation.status = .modified
    }
}
