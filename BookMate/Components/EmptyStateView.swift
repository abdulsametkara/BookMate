import SwiftUI

struct EmptyStateView: View {
    var message: String
    var buttonText: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: action) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            message: "Henüz kitap eklemediniz",
            buttonText: "Kitap Ekle",
            icon: "book.fill"
        ) {
            print("Button tapped")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 