import SwiftUI

struct ReadingTimerView: View {
    @StateObject var viewModel = ReadingTimerViewModel()
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @State private var selectedBook: Book?
    @State private var showBookPicker = false
    @State private var timerScale: CGFloat = 1.0
    @State private var showStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Kitap seçimi
                    bookSelectionView
                    
                    // Zamanlayıcı görüntüsü
                    timerDisplayView
                    
                    // Zamanlayıcı kontrolleri
                    timerControlsView
                    
                    // Günlük istatistikler
                    if showStats || viewModel.secondsElapsed > 0 {
                        statisticsView
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Okuma Zamanlayıcısı")
            .navigationBarItems(
                trailing: Button(action: {
                    showStats.toggle()
                }) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showBookPicker) {
                bookPickerView
            }
        }
    }
    
    // Kitap seçim alanı
    private var bookSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kitap")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: {
                if !viewModel.timerActive {
                    showBookPicker = true
                }
            }) {
                HStack {
                    if let book = selectedBook {
                        // Seçilen kitap gösterimi
                        bookCoverView(book: book)
                        
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        // Kitap seçimi yok
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Bir kitap seçin")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !viewModel.timerActive {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .disabled(viewModel.timerActive)
        }
    }
    
    // Zamanlayıcı göstergesi
    private var timerDisplayView: some View {
        VStack {
            ZStack {
                // Dış çember
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 15)
                
                // Zamanlayıcı çemberi
                Circle()
                    .trim(from: 0, to: min(CGFloat(viewModel.secondsElapsed) / 3600, 1))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Süre göstergesi
                VStack {
                    Text(viewModel.formattedTime(seconds: viewModel.secondsElapsed))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .scaleEffect(timerScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerScale)
                        .onAppear {
                            // Nabız efekti
                            withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                if viewModel.timerActive {
                                    timerScale = 1.05
                                }
                            }
                        }
                        .onChange(of: viewModel.timerActive) { newValue in
                            if newValue {
                                // Zamanlayıcı aktif olduğunda nabız efekti
                                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                    timerScale = 1.05
                                }
                            } else {
                                // Durduğunda normal boyut
                                withAnimation {
                                    timerScale = 1.0
                                }
                            }
                        }
                    
                    if viewModel.secondsElapsed > 0 {
                        Text(viewModel.timerActive ? "Okuma Devam Ediyor" : "Duraklatıldı")
                            .font(.subheadline)
                            .foregroundColor(viewModel.timerActive ? .green : .orange)
                    }
                }
            }
            .frame(width: 250, height: 250)
        }
    }
    
    // Zamanlayıcı kontrolleri
    private var timerControlsView: some View {
        HStack(spacing: 30) {
            // Sol buton (Reset/Durdur)
            Button(action: {
                if viewModel.secondsElapsed > 0 {
                    viewModel.stopTimer()
                } else {
                    viewModel.resetTimer()
                }
                
                // Haptik geribildirim
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }) {
                Image(systemName: viewModel.secondsElapsed > 0 ? "stop.fill" : "arrow.counterclockwise")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(viewModel.secondsElapsed > 0 ? Color.red : Color.gray)
                    .cornerRadius(30)
                    .shadow(radius: 5)
            }
            .disabled(selectedBook == nil && !viewModel.timerActive)
            
            // Orta buton (Başlat/Duraklat)
            Button(action: {
                if !viewModel.timerActive {
                    if viewModel.secondsElapsed == 0 && selectedBook != nil {
                        viewModel.startTimer(bookId: selectedBook!.id)
                    } else {
                        viewModel.resumeTimer()
                    }
                } else {
                    viewModel.pauseTimer()
                }
                
                // Haptik geribildirim
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                Image(systemName: viewModel.timerActive ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        viewModel.timerActive ? 
                            Color.orange : 
                            (selectedBook == nil ? Color.gray : Color.green)
                    )
                    .cornerRadius(40)
                    .shadow(radius: 5)
            }
            .disabled(selectedBook == nil && !viewModel.timerActive)
        }
    }
    
    // İstatistikler
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Okuma İstatistikleri")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 20) {
                // Günlük okuma süresi
                VStack {
                    Text(viewModel.formattedTime(seconds: viewModel.todaysTotalReadingTime))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Bugün")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Toplam okuma süresi
                VStack {
                    Text(viewModel.formattedTime(seconds: viewModel.allTimeTotalReadingTime))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Toplam")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // Kitap seçim ekranı
    private var bookPickerView: some View {
        NavigationView {
            List {
                // Devam edilenler
                Section(header: Text("Devam Edilen Kitaplar")) {
                    ForEach(libraryViewModel.books.filter { $0.progress > 0 && $0.progress < 1.0 }) { book in
                        Button(action: {
                            selectedBook = book
                            showBookPicker = false
                        }) {
                            HStack {
                                bookCoverView(book: book)
                                
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.headline)
                                    
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    // İlerleme göstergesi
                                    ProgressView(value: book.progress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                    
                                    Text("\(Int(book.progress * 100))% tamamlandı")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Tüm kitaplar
                Section(header: Text("Tüm Kitaplar")) {
                    ForEach(libraryViewModel.books) { book in
                        Button(action: {
                            selectedBook = book
                            showBookPicker = false
                        }) {
                            HStack {
                                bookCoverView(book: book)
                                
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.headline)
                                    
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Kitap Seçin")
            .navigationBarItems(trailing: Button("İptal") {
                showBookPicker = false
            })
        }
    }
    
    // Kitap kapağı
    private func bookCoverView(book: Book) -> some View {
        Group {
            if let coverImageURL = book.coverImageURL, let url = URL(string: coverImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 90)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(8)
                    case .failure:
                        defaultCoverView(book: book)
                    @unknown default:
                        defaultCoverView(book: book)
                    }
                }
            } else {
                defaultCoverView(book: book)
            }
        }
    }
    
    // Varsayılan kitap kapağı
    private func defaultCoverView(book: Book) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.random)
                .frame(width: 60, height: 90)
                .cornerRadius(8)
            
            Text(book.title.prefix(1))
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// Rastgele renk uzantısı (model için)
extension Color {
    static var random: Color {
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .red, .yellow, .cyan, .mint]
        return colors.randomElement() ?? .blue
    }
}

struct ReadingTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingTimerView()
            .environmentObject(LibraryViewModel())
    }
} 