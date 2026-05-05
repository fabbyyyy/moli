import SwiftUI
import UIKit

struct ProductRecommendationCard: View {
    @Binding var recommendation: Recommendation

    private var subtotalText: String {
        let subtotal = recommendation.product.unitPriceMXN * Double(recommendation.editableQuantity)
        return subtotal.formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }

    private var unitPriceText: String {
        recommendation.product.unitPriceMXN.formatted(.currency(code: "MXN").precision(.fractionLength(0)))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ProductPhoto(product: recommendation.product)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.product.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(recommendation.product.brand)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.mutedGray)

                    Text("\(unitPriceText) c/u")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.primaryBlue)
                }
                
                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(subtotalText)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                
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

private struct ProductPhoto: View {
    let product: Product

    var body: some View {
        Group {
            if let imageName = product.imageName, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.headline)
                    Text(product.name.prefix(1))
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundColor(AppTheme.Colors.primaryBlue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.softBlue)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.small))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.small)
                .stroke(AppTheme.Colors.primaryBlue.opacity(0.12), lineWidth: 1)
        )
    }
}
