import SwiftUI

struct CoupleView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var partnerCode = ""
    @State private var isShowingQRCode = false
    @State private var isConnecting = false
    @State private var showScanner = false
    @State private var hasPartner = false
    
    // Demo partner bilgileri (gerçek uygulamada Firebase'den gelecek)
    let demoPartner = PartnerInfo(
        id: "partner123",
        name: "Ayşe Yılmaz",
        profileImageURL: nil,
        connectionDate: Date().addingTimeInterval(-3600 * 24 * 30), // 30 gün önce
        statistics: PartnerStatistics(
            booksRead: 12,
            pagesRead: 3456,
            currentStreak: 5,
            favoriteGenre: "Bilim Kurgu"
        )
    )
    
    // Demo ortak kitaplar
    let demoSharedBooks = [
        Book(id: "1", title: "Dune", author: "Frank Herbert", coverURL: nil, isbn: "9780441172719", pageCount: 412, currentPage: 200, dateAdded: Date(), dateFinished: nil, genre: "Bilim Kurgu", notes: nil, isFavorite: true, rating: nil),
        Book(id: "2", title: "1984", author: "George Orwell", coverURL: nil, isbn: "9780451524935", pageCount: 328, currentPage: 100, dateAdded: Date(), dateFinished: nil, genre: "Distopya", notes: nil, isFavorite: false, rating: nil),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if hasPartner {
                        // Partner bilgisi ve görünümü
                        connectedPartnerView
                        
                        // Ortak kitaplık
                        sharedLibraryView
                        
                        // Ortak hedefler
                        sharedGoalsView
                        
                        // Kilometre taşları
                        milestonesView
                    } else {
                        // Eşleşme yok, bağlanma sayfası
                        connectionView
                    }
                }
                .padding()
            }
            .navigationTitle("Partner Eşleşmesi")
            .onAppear {
                // Demo: partner bilgisi var gibi davran
                // Gerçek uygulamada Firebase'den kontrol edilecek
                hasPartner = true
            }
            .sheet(isPresented: $isShowingQRCode) {
                QRCodeView(code: "PARTNER_123456")
            }
            .sheet(isPresented: $showScanner) {
                QRScannerView { code in
                    self.partnerCode = code
                    self.showScanner = false
                    // Normalde burada eşleşme işlemi yapılır
                }
            }
        }
    }
    
    // MARK: - UI Bileşenleri
    
    // Bağlı partner görünümü
    private var connectedPartnerView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Eşleştiğiniz Partner")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: PartnerDetailView(partner: demoPartner)) {
                    Text("Detaylar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 20) {
                // Partner fotoğrafı
                if let imageURL = demoPartner.profileImageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(demoPartner.name)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("\(Int(Date().timeIntervalSince(demoPartner.connectionDate) / 86400)) gündür bağlı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // İstatistikler
                    HStack(spacing: 15) {
                        StatItem(value: "\(demoPartner.statistics.booksRead)", label: "Kitap")
                        StatItem(value: "\(demoPartner.statistics.currentStreak)", label: "Seri")
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // Ortak kitaplık görünümü
    private var sharedLibraryView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Ortak Kitaplık")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: SharedLibraryView(books: demoSharedBooks)) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            if demoSharedBooks.isEmpty {
                EmptyStateView(message: "Henüz ortak kitap yok", systemImage: "books.vertical")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(demoSharedBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                SharedBookCardView(book: book)
                                    .frame(width: 160, height: 220)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Ortak hedefler görünümü
    private var sharedGoalsView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Ortak Hedefler")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Yeni hedef ekleme sayfasını aç
                }) {
                    Image(systemName: "plus")
                }
            }
            
            // Demo hedefler (gerçek uygulamada Firebase'den gelir)
            VStack(spacing: 10) {
                GoalItemView(
                    title: "Haftalık Okuma Hedefi",
                    description: "Her gün en az 20 dakika okuma",
                    progress: 0.7,
                    remainingText: "3 gün kaldı"
                )
                
                GoalItemView(
                    title: "Yaz Okuma Listesi",
                    description: "10 kitaplık ortak okuma listesi",
                    progress: 0.4,
                    remainingText: "6 kitap kaldı"
                )
            }
        }
    }
    
    // Kilometre taşları görünümü
    private var milestonesView: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Kilometre Taşları")
                    .font(.headline)
                
                Spacer()
            }
            
            // Demo kilometre taşları
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    MilestoneCardView(
                        title: "İlk Ay",
                        description: "1 ay birlikte okuma",
                        iconName: "calendar",
                        color: .blue
                    )
                    
                    MilestoneCardView(
                        title: "5 Kitap",
                        description: "5 kitap birlikte okudunuz",
                        iconName: "books.vertical",
                        color: .green
                    )
                    
                    MilestoneCardView(
                        title: "Seri Okuyucular",
                        description: "7 gün üst üste okuma",
                        iconName: "flame",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // Eşleşme görünümü
    private var connectionView: some View {
        VStack(spacing: 25) {
            // Resim
            Image(systemName: "person.2.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)
            
            // Başlık ve açıklama
            Text("Partnerinizle Eşleşin")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Partnerinizle eşleşerek okuma deneyiminizi paylaşın, birlikte hedefler belirleyin ve motivasyonunuzu artırın.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Seçenekler
            VStack(spacing: 15) {
                // QR kod ile eşleşme
                Button(action: {
                    isShowingQRCode = true
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                            .font(.title3)
                        
                        Text("QR Kod Oluştur")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // QR kod tarama
                Button(action: {
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title3)
                        
                        Text("QR Kod Tara")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Kod ile eşleşme
                HStack {
                    TextField("Partner kodu girin", text: $partnerCode)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    
                    Button(action: {
                        isConnecting = true
                        // Burada eşleşme işlemi yapılır
                        isConnecting = false
                    }) {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Bağlan")
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(partnerCode.isEmpty || isConnecting)
                }
            }
            .padding(.top)
        }
    }
}

// MARK: - Yardımcı Yapılar ve Görünümler

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SharedBookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            // Kitap kapağı
            ZStack {
                if let coverURL = book.coverURL {
                    AsyncImage(url: coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 110, height: 150)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 150)
                        .overlay(
                            Text(book.title)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(5)
                        )
                }
            }
            .cornerRadius(8)
            .shadow(radius: 2)
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Partner okuma durumu
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    
                    Text("Siz: \(Int(book.readingProgress))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                    
                    Text("Ayşe: 75%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 5)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct GoalItemView: View {
    let title: String
    let description: String
    let progress: Double
    let remainingText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
            
            Text(remainingText)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MilestoneCardView: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(color)
                .padding()
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120, height: 160)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Yardımcı Görünümler

// QR Kod görünümü
struct QRCodeView: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("QR Kodunuz")
                .font(.title2)
                .fontWeight(.bold)
            
            // Gerçek uygulamada CoreImage ile QR kod oluşturulur
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            
            Text("Partnerinizden bu kodu taramasını isteyin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Partner Kodu: \(code)")
                .font(.headline)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Button("Kapat") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}

// QR Kod tarayıcı görünümü (demo)
struct QRScannerView: View {
    var completionHandler: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("QR Kod Tarayıcı")
                .font(.title2)
                .padding()
            
            Spacer()
            
            // Demo: Gerçek bir tarayıcı yerine bir simülasyon
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                .frame(width: 250, height: 250)
                .overlay(
                    Image(systemName: "camera")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                )
            
            Spacer()
            
            // Demo: QR kod simülasyonu için bir buton
            Button("QR Kodu Simüle Et") {
                completionHandler("PARTNER_654321")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom)
        }
    }
}

// Partner detay görünümü
struct PartnerDetailView: View {
    let partner: PartnerInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Partner Detayları")
                    .font(.title)
                    .padding(.horizontal)
            }
        }
        .navigationTitle(partner.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Ortak kitaplık görünümü
struct SharedLibraryView: View {
    let books: [Book]
    
    var body: some View {
        List {
            ForEach(books) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRowView(book: book)
                }
            }
        }
        .navigationTitle("Ortak Kitaplık")
        .listStyle(PlainListStyle())
    }
}

// MARK: - Veri Yapıları

struct PartnerInfo {
    let id: String
    let name: String
    let profileImageURL: URL?
    let connectionDate: Date
    let statistics: PartnerStatistics
}

struct PartnerStatistics {
    let booksRead: Int
    let pagesRead: Int
    let currentStreak: Int
    let favoriteGenre: String
}

struct CoupleView_Previews: PreviewProvider {
    static var previews: some View {
        CoupleView()
            .environmentObject(AuthViewModel())
    }
} 