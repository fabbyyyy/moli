import SwiftUI

struct MapRouteMockView: View {
    var body: some View {
        ZStack {
            // Background beige map color
            Color(hex: "F2ECE0").ignoresSafeArea()
            
            // Grid lines for streets
            VStack(spacing: 40) {
                ForEach(0..<20) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(height: 8)
                }
            }
            
            HStack(spacing: 40) {
                ForEach(0..<10) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 8)
                }
            }
            
            // Some green areas
            VStack {
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "D0DFB8").opacity(0.6))
                        .frame(width: 150, height: 100)
                        .padding(.trailing, 40)
                        .padding(.top, 100)
                }
                Spacer()
            }
            
            // Route line (approximate mock)
            Path { path in
                path.move(to: CGPoint(x: 150, y: 300))
                path.addLine(to: CGPoint(x: 200, y: 250))
                path.addLine(to: CGPoint(x: 250, y: 350))
                path.addLine(to: CGPoint(x: 230, y: 480))
                path.addLine(to: CGPoint(x: 150, y: 550))
            }
            .stroke(AppTheme.Colors.primaryBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            
            // Route line inner
            Path { path in
                path.move(to: CGPoint(x: 150, y: 300))
                path.addLine(to: CGPoint(x: 200, y: 250))
                path.addLine(to: CGPoint(x: 250, y: 350))
                path.addLine(to: CGPoint(x: 230, y: 480))
                path.addLine(to: CGPoint(x: 150, y: 550))
            }
            .stroke(Color(hex: "5A67A6"), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            // Points
            pointView(x: 150, y: 300, isCurrent: false)
            pointView(x: 200, y: 250, isCurrent: false)
            pointView(x: 250, y: 350, isCurrent: false)
            pointView(x: 230, y: 480, isCurrent: false)
            pointView(x: 150, y: 550, isCurrent: true, label: "6")
        }
    }
    
    @ViewBuilder
    func pointView(x: CGFloat, y: CGFloat, isCurrent: Bool, label: String = "✓") -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .shadow(radius: 2)
            
            Circle()
                .fill(isCurrent ? AppTheme.Colors.primaryBlue : AppTheme.Colors.mutedGray.opacity(0.7))
                .frame(width: 26, height: 26)
            
            if isCurrent {
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .position(x: x, y: y)
    }
}
