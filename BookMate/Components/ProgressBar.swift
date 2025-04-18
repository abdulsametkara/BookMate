import SwiftUI

struct ProgressBar: View {
    var value: Double // 0.0 - 1.0 arasında
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(backgroundColor)
                    .cornerRadius(geometry.size.height / 2)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(foregroundColor)
                    .cornerRadius(geometry.size.height / 2)
                    .animation(.linear, value: value)
            }
        }
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar(value: 0.72)
            .frame(height: 10)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 