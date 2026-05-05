import SwiftUI

struct ShelfMockView: View {
    let showGuides: Bool
    
    let shelfColors: [Color] = [
        Color(hex: "E53935"), // Red
        Color(hex: "FDD835"), // Yellow
        Color(hex: "5E35B1"), // Purple
        Color(hex: "1E88E5"), // Blue
        Color(hex: "FB8C00"), // Orange
        Color(hex: "43A047"), // Green
        Color(hex: "D81B60"), // Pink
        Color(hex: "E53935")  // Red
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            shelfRow(gaps: [])
            shelfRow(gaps: [2, 6])
            shelfRow(gaps: [4])
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    func shelfRow(gaps: [Int]) -> some View {
        ZStack(alignment: .bottom) {
            // Background shelf back
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "3E352B"))
                .frame(height: 120)
            
            // Products
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<8, id: \.self) { index in
                    if gaps.contains(index) {
                        // Gap
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .background(Color.black.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    } else {
                        // Product Box
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shelfColors[index])
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            // Simulated depth
                            .overlay(
                                LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            
            // Guide line
            if showGuides {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(height: 1)
                    .offset(y: -60)
            }
            
            // Shelf base
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "5D4A3D"))
                .frame(height: 12)
        }
    }
}
