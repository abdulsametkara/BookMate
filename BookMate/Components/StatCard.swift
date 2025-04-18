import SwiftUI

struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            StatCard(
                title: "Bugün",
                value: "45 dk",
                icon: "clock",
                color: .blue
            )
            
            StatCard(
                title: "Toplam",
                value: "32 kitap",
                icon: "book.closed",
                color: .green
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 