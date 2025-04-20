import SwiftUI
import SceneKit

struct BookshelfView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    @State private var scene: SCNScene?
    @State private var bookCount = 5
    @State private var isLoading = true
    @State private var memoryUsage: Double = 5
    @State private var renderTime: Double = 15
    @State private var fps: Int = 60
    
    // Performans izlemesi için zamanlayıcı
    @State private var performanceTimer: Timer?
    
    var body: some View {
        VStack {
            // 3D Kitaplık gösterimi
            ZStack {
                SceneView(
                    scene: scene,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .frame(height: 450)
                .onAppear {
                    setupScene()
                    startPerformanceMonitoring()
                }
                .onDisappear {
                    stopPerformanceMonitoring()
                }
                
                if isLoading {
                    ProgressView("Kitaplık yükleniyor...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(10)
                }
            }
            
            // Kitaplık kontrol paneli
            VStack(spacing: 20) {
                Text("3D Kitaplık")
                    .font(.headline)
                
                HStack {
                    Text("Kitaplığınızdaki kitaplar: \(bookViewModel.userLibrary.count)")
                    Spacer()
                }
                
                // Performans metrikleri
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performans Metrikleri")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.bottom, 4)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Bellek Kullanımı:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Render Süresi:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("FPS:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(memoryUsage, specifier: "%.1f") MB")
                                .font(.caption)
                                .foregroundColor(memoryUsage > 20 ? .red : .green)
                            
                            Text("\(renderTime, specifier: "%.1f") ms")
                                .font(.caption)
                                .foregroundColor(renderTime > 50 ? .orange : .green)
                            
                            Text("\(fps)")
                                .font(.caption)
                                .foregroundColor(fps < 30 ? .red : .green)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Optimizasyon seçenekleri
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optimizasyon Seçenekleri")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.bottom, 4)
                    
                    Toggle("Düşük Poligon Modlar", isOn: .constant(true))
                        .font(.caption)
                    
                    Toggle("LOD (Detay Seviyesi)", isOn: .constant(true))
                        .font(.caption)
                    
                    Toggle("Mipmap Dokuları", isOn: .constant(true))
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func setupScene() {
        isLoading = true
        
        // Performans simülasyonu için kısa bir gecikme
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Boş bir sahne oluşturma
            scene = SCNScene()
            
            // Basit bir kitaplık raf modeli oluşturma
            let shelfNode = createShelf()
            scene?.rootNode.addChildNode(shelfNode)
            
            // Kitapları oluştur
            addBooks(to: shelfNode, books: bookViewModel.userLibrary)
            
            // Kamera ayarları
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
            scene?.rootNode.addChildNode(cameraNode)
            
            // Performans optimizasyon ayarları
            applySceneOptimizations()
            
            isLoading = false
        }
    }
    
    private func applySceneOptimizations() {
        guard let scene = scene else { return }
        
        // Sahne pauzlama kontrolü - görünür olmadığında renderingi durdur
        scene.isPaused = false
        
        // Arka plan optimizasyonu
        scene.background.contents = UIColor.systemBackground
        
        // Fizik simülasyonu optimizasyonu (kitaplar için fizik kullanmıyoruz)
        scene.physicsWorld.speed = 0
        
        // Frustum culling - görünmeyen nesneleri renderleme
        scene.rootNode.childNodes.forEach { node in
            node.rendererDelegate = nil
            node.isPaused = false
            
            // İlişkili geometrilerin optimizasyonu
            if let geometry = node.geometry {
                // Vertex buffer optimizasyonu
                geometry.firstMaterial?.isDoubleSided = false
                
                // Level of Detail (LOD) ayarları
                let simplifiedGeometry = simplifyGeometry(geometry)
                let lod = SCNLevelOfDetail(geometry: simplifiedGeometry, screenSpaceRadius: 100)
                geometry.levelsOfDetail = [lod]
                
                // Gölgeleme optimizasyonu
                geometry.firstMaterial?.lightingModel = .phong
                geometry.firstMaterial?.diffuse.mipFilter = .linear
            }
        }
    }
    
    private func simplifyGeometry(_ geometry: SCNGeometry) -> SCNGeometry {
        // Bu fonksiyon gerçek uygulamada daha karmaşık olabilir
        // Şimdilik sadece basitleştirilmiş bir kutu dönüyor
        if let box = geometry as? SCNBox {
            return SCNBox(width: box.width, height: box.height, length: box.length, chamferRadius: 0)
        }
        return geometry
    }
    
    private func addBooks(to shelfNode: SCNNode, books: [Book]) {
        // Kullanıcının kitaplarını gösterme
        let bookColors: [UIColor] = [.red, .blue, .green, .purple, .orange, .cyan, .magenta, .yellow]
        let count = min(books.count, 20) // En fazla 20 kitap göster
        bookCount = count
        
        // Kitaplar için nesne havuzu (object pooling) kullanıyoruz
        let bookGeometries = createBookGeometryPool(colorCount: bookColors.count)
        
        for i in 0..<count {
            // Performans için nesne havuzundan geometri al
            let colorIndex = i % bookColors.count
            let book = books[i]
            let bookGeometry = bookGeometries[colorIndex]
            
            let bookNode = SCNNode(geometry: bookGeometry)
            bookNode.name = "book" // Kolay tanımlama için isim verme
            
            // Kitapların raflara düzgün yerleşmesi için pozisyon hesaplama
            if i < 10 {
                // İlk raf
                bookNode.position = SCNVector3(x: -4.5 + Float(i) * 1.0, y: 1.6, z: 0)
            } else {
                // İkinci raf
                bookNode.position = SCNVector3(x: -4.5 + Float(i - 10) * 1.0, y: 3.0, z: 0)
            }
            
            // Kitapları hafif açıyla yerleştirme (çeşitlilik için)
            bookNode.eulerAngles.y = Float.random(in: -0.05...0.05)
            
            shelfNode.addChildNode(bookNode)
        }
        
        // Performans metriklerini güncelle
        updatePerformanceMetrics()
    }
    
    private func createShelf() -> SCNNode {
        // Raf oluşturma
        let shelfGeometry = SCNBox(width: 10, height: 0.5, length: 3, chamferRadius: 0)
        let shelfMaterial = SCNMaterial()
        shelfMaterial.diffuse.contents = UIColor.brown
        shelfGeometry.materials = [shelfMaterial]
        
        let shelfNode = SCNNode(geometry: shelfGeometry)
        shelfNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        // Arka panel oluşturma - optimizasyon için düşük detay kullanıyoruz
        let backPanel = SCNBox(width: 10, height: 7, length: 0.2, chamferRadius: 0)
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = UIColor.brown.withAlphaComponent(0.8)
        backPanel.materials = [backMaterial]
        
        let backNode = SCNNode(geometry: backPanel)
        backNode.position = SCNVector3(x: 0, y: 3.5, z: -1.5)
        shelfNode.addChildNode(backNode)
        
        return shelfNode
    }
    
    private func createBookGeometryPool(colorCount: Int) -> [SCNGeometry] {
        // Kitap renkleri
        let bookColors: [UIColor] = [.red, .blue, .green, .purple, .orange, .cyan, .magenta, .yellow]
        var geometryPool: [SCNGeometry] = []
        
        // Her renk için bir geometri önden hazırlanır (nesne havuzu yaklaşımı)
        for i in 0..<colorCount {
            // Optimize edilmiş kitap geometrisi
            let bookHeight = Float.random(in: 1.8...2.3)
            let bookWidth = Float.random(in: 0.8...1.2)
            let bookThickness = Float.random(in: 0.4...0.6)
            
            let bookGeometry = SCNBox(width: CGFloat(bookWidth), 
                                      height: CGFloat(bookHeight), 
                                      length: CGFloat(bookThickness), 
                                      chamferRadius: 0)
            
            // Kitap materyalleri
            let coverMaterial = SCNMaterial()
            coverMaterial.diffuse.contents = bookColors[i]
            
            let pageMaterial = SCNMaterial()
            pageMaterial.diffuse.contents = UIColor.white
            
            let spineMaterial = SCNMaterial()
            spineMaterial.diffuse.contents = bookColors[i].withAlphaComponent(0.8)
            
            // Kitap modelinin tüm yüzeylerine materyal atama
            bookGeometry.materials = [coverMaterial, coverMaterial, spineMaterial, spineMaterial, pageMaterial, pageMaterial]
            
            geometryPool.append(bookGeometry)
        }
        
        return geometryPool
    }
    
    // Performans izleme başlatma
    private func startPerformanceMonitoring() {
        stopPerformanceMonitoring() // Varsa önceki zamanlayıcıyı durdur
        
        // Her 1 saniyede bir performans metriklerini güncelle
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updatePerformanceMetrics()
        }
    }
    
    // Performans izlemeyi durdurma
    private func stopPerformanceMonitoring() {
        performanceTimer?.invalidate()
        performanceTimer = nil
    }
    
    // Performans metriklerini güncelleme
    private func updatePerformanceMetrics() {
        // Gerçek bir uygulamada, bu değerler gerçek sistem kaynaklarından alınır
        // Burada simüle edilmiş değerler kullanıyoruz
        memoryUsage = Double(5 + bookCount * 2) // Kitap başına 2MB ekler
        renderTime = Double(bookCount * 3) // Kitap başına 3ms render süresi
        fps = max(60 - bookCount, 15) // Kitap sayısı arttıkça FPS düşer, minimum 15
    }
}

struct BookshelfView_Previews: PreviewProvider {
    static var previews: some View {
        BookshelfView()
    }
} 