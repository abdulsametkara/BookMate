import SwiftUI

struct SectionHeader<Destination: View>: View {
    var title: String
    var showAll: Bool
    var destination: Destination
    
    init(title: String, showAll: Bool = false, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.showAll = showAll
        self.destination = destination()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            if showAll {
                NavigationLink(destination: destination) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader(title: "Son Eklenenler", showAll: true) {
            Text("Tüm Kitaplar")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 