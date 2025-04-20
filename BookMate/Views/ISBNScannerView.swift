import SwiftUI
import AVFoundation
import Vision

struct ISBNScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var scannerModel = ISBNScannerModel()
    @State private var isShowingSettings = false
    @State private var showBookDetails = false
    @State private var scannedBook: Book?
    
    var body: some View {
        ZStack {
            // Kamera arka planı
            ISBNScannerViewRepresentable(scannerModel: scannerModel)
                .edgesIgnoringSafeArea(.all)
            
            // Tarama alanı göstergesi
            RoundedRectangle(cornerRadius: 12)
                .stroke(scannerModel.isScanning ? Color.green : Color.white, lineWidth: 3)
                .frame(width: 280, height: 100)
                .overlay(
                    VStack {
                        if let detectedISBN = scannerModel.detectedISBN {
                            Text("ISBN: \(detectedISBN)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(6)
                        }
                        
                        if scannerModel.isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        }
                    }
                )
            
            // Kontrol paneli
            VStack {
                HStack {
                    // Kapatma butonu
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Ayarlar butonu
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.headline)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Alt kontrol panel
                VStack(spacing: 20) {
                    // Flash butonu
                    Button(action: { scannerModel.toggleTorch() }) {
                        Image(systemName: scannerModel.isTorchOn ? "bolt.fill" : "bolt.slash")
                            .font(.system(size: 20))
                            .padding(15)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    // Manuel giriş butonu
                    Button(action: { scannerModel.showManualEntry = true }) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 20))
                            .padding(15)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    Text(scannerModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
                .padding(.bottom, 40)
            }
            
            // Manuel ISBN girişi
            if scannerModel.showManualEntry {
                ISBNManualEntryView(isPresented: $scannerModel.showManualEntry, onSubmit: { isbn in
                    scannerModel.searchBookByISBN(isbn: isbn)
                })
                .transition(.opacity)
                .animation(.easeInOut, value: scannerModel.showManualEntry)
            }
        }
        .alert(item: $scannerModel.error) { error in
            Alert(
                title: Text("Hata"),
                message: Text(error.message),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .sheet(isPresented: $isShowingSettings) {
            ScannerSettingsView(scannerModel: scannerModel)
        }
        .sheet(isPresented: $scannerModel.showBookPreview) {
            if let book = scannerModel.scannedBook {
                ScannedBookPreviewView(book: book, onAdd: { book in
                    scannedBook = book
                    scannerModel.showBookPreview = false
                    showBookDetails = true
                    scannerModel.reset()
                }, onCancel: {
                    scannerModel.reset()
                })
            }
        }
        .fullScreenCover(isPresented: $showBookDetails) {
            if let book = scannedBook {
                BookDetailView(book: book)
            }
        }
        .onAppear {
            scannerModel.startScanning()
        }
        .onDisappear {
            scannerModel.stopScanning()
        }
    }
}

// UIKit entegrasyonu için UIViewControllerRepresentable
struct ISBNScannerViewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var scannerModel: ISBNScannerModel
    
    func makeUIViewController(context: Context) -> ISBNScannerViewController {
        return ISBNScannerViewController(scannerModel: scannerModel)
    }
    
    func updateUIViewController(_ uiViewController: ISBNScannerViewController, context: Context) {
        // Görünüm güncellemeleri
        if scannerModel.isTorchOn != uiViewController.isTorchOn {
            uiViewController.toggleTorch()
        }
    }
}

// Tarayıcı mantığını içeren UIViewController
class ISBNScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scannerModel: ISBNScannerModel
    
    var isTorchOn = false
    
    init(scannerModel: ISBNScannerModel) {
        self.scannerModel = scannerModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let captureSession = captureSession, !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCaptureSession() {
        // Yakalama oturumu oluştur
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        // Kamera giriş cihazını ayarla
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            scannerModel.setError(message: "Kamera erişilemez")
            return
        }
        
        // Video girişi oluştur
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            scannerModel.setError(message: "Kamera girişi oluşturulamadı")
            return
        }
        
        // Giriş ve çıkışları ayarla
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            scannerModel.setError(message: "Kamera giriş eklenemedi")
            return
        }
        
        // Metadata çıkışı ekle
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code39, .code128]
        } else {
            scannerModel.setError(message: "Metadata çıkışı eklenemedi")
            return
        }
        
        // Önizleme katmanı oluştur
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        // Oturumu başlat
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }
    
    // Barkod yakalandığında çağrılır
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Birden çok barkod bulunduğunda ilkini kullan
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            // ISBN doğrulama ve arama
            if self.isValidISBN(stringValue) {
                scannerModel.detectedISBN = stringValue
                scannerModel.searchBookByISBN(isbn: stringValue)
            }
        }
    }
    
    // ISBN doğrulama
    private func isValidISBN(_ code: String) -> Bool {
        // Sadece sayıları içeren ve 10 veya 13 karakter uzunluğunda metni kabul et
        let cleaned = code.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
        return (cleaned.count == 10 || cleaned.count == 13) && cleaned.allSatisfy { $0.isNumber }
    }
    
    // Feneri aç/kapat
    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                isTorchOn = !isTorchOn
                device.torchMode = isTorchOn ? .on : .off
                
                device.unlockForConfiguration()
            } catch {
                scannerModel.setError(message: "Fener açılamadı")
            }
        }
    }
}

// ISBN Tarayıcı ViewModel
class ISBNScannerModel: ObservableObject {
    @Published var isScanning = false
    @Published var detectedISBN: String?
    @Published var scannedBook: Book?
    @Published var error: ScannerError?
    @Published var showManualEntry = false
    @Published var showBookPreview = false
    @Published var isSearching = false
    @Published var isTorchOn = false
    @Published var statusMessage = "Barkodu tarama alanına yerleştirin"
    
    private let bookService = GoogleBooksService.shared
    private var cancellables = Set<AnyCancellable>()
    
    func startScanning() {
        isScanning = true
        statusMessage = "Barkodu tarama alanına yerleştirin"
    }
    
    func stopScanning() {
        isScanning = false
    }
    
    func toggleTorch() {
        isTorchOn.toggle()
    }
    
    func setError(message: String) {
        DispatchQueue.main.async {
            self.error = ScannerError(message: message)
        }
    }
    
    func searchBookByISBN(isbn: String) {
        // Zaten arama yapılıyorsa, tekrarlama
        guard !isSearching else { return }
        
        isSearching = true
        statusMessage = "ISBN \(isbn) aranıyor..."
        stopScanning()
        
        // Google Books API'den kitap bilgisini getir
        Task {
            do {
                guard let book = try await bookService.searchBookByISBN(isbn) else {
                    throw NSError(domain: "ISBNScanner", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kitap bulunamadı"])
                }
                
                DispatchQueue.main.async {
                    self.scannedBook = book
                    self.showBookPreview = true
                    self.isSearching = false
                    self.statusMessage = "Kitap bulundu: \(book.title)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.setError(message: "Kitap bulunamadı: \(error.localizedDescription)")
                    self.isSearching = false
                    self.startScanning()
                    self.statusMessage = "Kitap bulunamadı. Tekrar deneyin."
                }
            }
        }
    }
    
    func reset() {
        detectedISBN = nil
        scannedBook = nil
        showBookPreview = false
        isSearching = false
        startScanning()
    }
}

// Hata modeli
struct ScannerError: Identifiable {
    let id = UUID()
    let message: String
}

// Manuel ISBN Giriş Görünümü
struct ISBNManualEntryView: View {
    @Binding var isPresented: Bool
    @State private var isbn = ""
    let onSubmit: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("ISBN Girin")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("ISBN numarası", text: $isbn)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .keyboardType(.numberPad)
                
                HStack(spacing: 20) {
                    Button("İptal") {
                        isPresented = false
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Ara") {
                        if !isbn.isEmpty {
                            onSubmit(isbn)
                            isPresented = false
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isbn.isEmpty)
                    .opacity(isbn.isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(20)
            .padding(40)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// Tarama Ayarları Görünümü
struct ScannerSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var scannerModel: ISBNScannerModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kamera Ayarları")) {
                    Toggle(isOn: $scannerModel.isTorchOn) {
                        Label("Fener", systemImage: "bolt.fill")
                    }
                }
                
                Section(header: Text("Tarama İpuçları")) {
                    VStack(alignment: .leading, spacing: 10) {
                        TipRow(icon: "barcode", text: "Barkodu iyi aydınlatılmış koşullarda tarayın")
                        TipRow(icon: "hand.raised", text: "Kamerayı sabit tutun ve barkoda odaklayın")
                        TipRow(icon: "plus.magnifyingglass", text: "ISBN barkodları genellikle kitabın arka kapağında bulunur")
                        TipRow(icon: "keyboard", text: "Tarama çalışmazsa, ISBN'i manuel olarak girebilirsiniz")
                    }
                    .padding(.vertical, 5)
                }
                
                Section(header: Text("Hakkında")) {
                    Text("Bu tarayıcı, kitapların ISBN barkodlarını tanımlamak ve kitap bilgilerini Google Books API'sinden almak için kullanılır.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Tarayıcı Ayarları")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// İpucu Satırı
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// Taranan Kitap Önizleme Görünümü
struct ScannedBookPreviewView: View {
    let book: Book
    let onAdd: (Book) -> Void
    let onCancel: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var rating: Int = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Kitap kapağı
                    if let coverURL = book.coverURL {
                        AsyncImage(url: coverURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 150, height: 220)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 220)
                                    .cornerRadius(8)
                                    .shadow(radius: 5)
                            case .failure:
                                Image(systemName: "book.closed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 220)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.top)
                    } else {
                        Image(systemName: "book.closed")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 220)
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                    
                    // Kitap bilgileri
                    VStack(alignment: .leading, spacing: 10) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack {
                            Text("Yazar:")
                                .fontWeight(.medium)
                            Text(book.author)
                                .foregroundColor(.secondary)
                        }
                        
                        if let isbn = book.isbn {
                            HStack {
                                Text("ISBN:")
                                    .fontWeight(.medium)
                                Text(isbn)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if book.pageCount > 0 {
                            HStack {
                                Text("Sayfa Sayısı:")
                                    .fontWeight(.medium)
                                Text("\(book.pageCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let genre = book.genre {
                            HStack {
                                Text("Tür:")
                                    .fontWeight(.medium)
                                Text(genre)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Puanlama
                        VStack(alignment: .leading) {
                            Text("Puanınız:")
                                .fontWeight(.medium)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                        .font(.title3)
                                        .onTapGesture {
                                            rating = star
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .padding(.horizontal)
                    
                    // Butonlar
                    HStack(spacing: 20) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            onCancel()
                        }) {
                            Text("İptal")
                                .fontWeight(.medium)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 25)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            var updatedBook = book
                            updatedBook.rating = rating
                            onAdd(updatedBook)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Kitaplığıma Ekle")
                                .fontWeight(.medium)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 25)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Kitap Önizleme")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
                onCancel()
            })
        }
    }
}

// Önizleme için
struct ISBNScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ISBNScannerView()
    }
} 