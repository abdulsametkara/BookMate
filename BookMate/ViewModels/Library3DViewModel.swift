import Foundation
import SceneKit
import Combine

class Library3DViewModel: ObservableObject {
    @Published var library3D: Library3D
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDisplayMode: Library3D.DisplayMode = .chronological
    
    private var cancellables = Set<AnyCancellable>()
    
    init(library3D: Library3D = Library3D()) {
        self.library3D = library3D
    }
    
    func loadLibrary(books: [Book]) {
        isLoading = true
        
        // Gerçek uygulamada veritabanından veya API'den yükleme yapılabilir
        // Bu örnekte tamamlanan kitapları kullanarak kütüphane oluşturuyoruz
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.library3D = Library3D.createSampleLibrary(with: books)
            self.isLoading = false
        }
    }
    
    func updateDisplayMode(to mode: Library3D.DisplayMode) {
        selectedDisplayMode = mode
        library3D.displayMode = mode
        library3D.organizeByDisplayMode()
    }
    
    func addBookToLibrary(_ book: Book) {
        guard book.progress >= 1.0 else { return }
        
        var updatedLibrary = self.library3D
        updatedLibrary.addBook(book)
        self.library3D = updatedLibrary
    }
    
    func updateViewRotation(to rotation: SCNVector4) {
        var updatedLibrary = self.library3D
        updatedLibrary.viewRotation = rotation
        self.library3D = updatedLibrary
    }
    
    // 3D kitaplık oluşturucu (SceneKit)
    func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Zemin
        let floorNode = createFloor()
        scene.rootNode.addChildNode(floorNode)
        
        // Işık ve kamera ayarları
        setupLightsAndCamera(scene: scene)
        
        // Kitaplıkları yükle
        for bookshelf in library3D.bookshelves {
            let bookshelfNode = createBookshelfNode(bookshelf: bookshelf)
            scene.rootNode.addChildNode(bookshelfNode)
        }
        
        return scene
    }
    
    // Zemin oluşturma
    private func createFloor() -> SCNNode {
        let floor = SCNBox(width: 10, height: 0.1, length: 10, chamferRadius: 0)
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -0.3, 0)
        return floorNode
    }
    
    // Işık ve kamera ayarları
    private func setupLightsAndCamera(scene: SCNScene) {
        // Ambient ışık
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.6, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Yönlü ışık
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1.0)
        directionalLight.eulerAngles = SCNVector3(GLKMathDegreesToRadians(-45), GLKMathDegreesToRadians(45), 0)
        scene.rootNode.addChildNode(directionalLight)
        
        // Kamera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 1.5, 5)
        cameraNode.look(at: SCNVector3(0, 0.5, 0))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    // Kitaplık oluşturma
    private func createBookshelfNode(bookshelf: Bookshelf) -> SCNNode {
        let bookshelfNode = SCNNode()
        bookshelfNode.position = bookshelf.position
        bookshelfNode.rotation = bookshelf.rotation
        
        // Kitaplık ana gövdesi
        let shelfWidth: Float = 1.2
        let shelfDepth: Float = 0.3
        let shelfHeight: Float = Float(bookshelf.levels.count * 25) / 100 + 0.1
        
        let shelfBox = SCNBox(width: CGFloat(shelfWidth), 
                              height: CGFloat(shelfHeight), 
                              length: CGFloat(shelfDepth), 
                              chamferRadius: 0.01)
        
        // Ahşap materyal
        let woodMaterial = SCNMaterial()
        woodMaterial.diffuse.contents = UIColor.brown
        woodMaterial.locksAmbientWithDiffuse = true
        woodMaterial.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        shelfBox.materials = [woodMaterial]
        
        let shelfBaseNode = SCNNode(geometry: shelfBox)
        shelfBaseNode.position = SCNVector3(0, shelfHeight/2 - 0.1, 0)
        bookshelfNode.addChildNode(shelfBaseNode)
        
        // Rafları oluştur
        for (i, level) in bookshelf.levels.enumerated() {
            let shelfLevelNode = createShelfLevel(level: level, levelIndex: i, shelfWidth: shelfWidth, shelfDepth: shelfDepth)
            bookshelfNode.addChildNode(shelfLevelNode)
            
            // Kitapları oluştur
            for (j, book) in level.books.enumerated() {
                let bookNode = createBookNode(book: book, index: j, levelIndex: i, shelfWidth: shelfWidth, shelfDepth: shelfDepth)
                bookshelfNode.addChildNode(bookNode)
            }
        }
        
        return bookshelfNode
    }
    
    // Raf seviyesi oluşturma
    private func createShelfLevel(level: BookshelfLevel, levelIndex: Int, shelfWidth: Float, shelfDepth: Float) -> SCNNode {
        let levelNode = SCNNode()
        
        // Raf tahtası
        let shelfBoard = SCNBox(width: CGFloat(shelfWidth), 
                                height: 0.02, 
                                length: CGFloat(shelfDepth), 
                                chamferRadius: 0.005)
        
        // Ahşap materyal
        let woodMaterial = SCNMaterial()
        woodMaterial.diffuse.contents = UIColor.brown
        woodMaterial.locksAmbientWithDiffuse = true
        woodMaterial.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        shelfBoard.materials = [woodMaterial]
        
        let shelfBoardNode = SCNNode(geometry: shelfBoard)
        let levelHeight: Float = Float(levelIndex) * 0.25
        shelfBoardNode.position = SCNVector3(0, levelHeight, 0)
        
        levelNode.addChildNode(shelfBoardNode)
        return levelNode
    }
    
    // Kitap düğümü oluşturma
    private func createBookNode(book: Book, index: Int, levelIndex: Int, shelfWidth: Float, shelfDepth: Float) -> SCNNode {
        let bookNode = SCNNode()
        
        // Kitap boyutları
        let bookHeight: Float = 0.2 + Float.random(in: 0...0.05)
        let bookWidth: Float = 0.03 + Float.random(in: 0...0.02)
        let bookDepth: Float = shelfDepth - 0.05
        
        let bookBox = SCNBox(width: CGFloat(bookWidth), 
                             height: CGFloat(bookHeight), 
                             length: CGFloat(bookDepth), 
                             chamferRadius: 0.002)
        
        // Kitap materyali - gerçek uygulamada kapak görseli kullanılabilir
        let coverMaterial = SCNMaterial()
        
        // Renk bazlı kategoriler için (gerçek uygulamada daha gelişmiş olabilir)
        var bookColor: UIColor
        
        if book.genre == "Roman" {
            bookColor = UIColor.blue
        } else if book.genre == "Distopya" {
            bookColor = UIColor.red
        } else if book.genre == "Klasik" {
            bookColor = UIColor.purple
        } else {
            // Rastgele bir renk
            bookColor = UIColor(
                red: CGFloat.random(in: 0.3...0.8),
                green: CGFloat.random(in: 0.3...0.8),
                blue: CGFloat.random(in: 0.3...0.8),
                alpha: 1.0
            )
        }
        
        coverMaterial.diffuse.contents = bookColor
        coverMaterial.specular.contents = UIColor(white: 0.3, alpha: 1.0)
        
        // Kitap sırt materyali
        let spineMaterial = SCNMaterial()
        spineMaterial.diffuse.contents = bookColor.withAlphaComponent(0.8)
        
        // Sayfa materyali
        let pageMaterial = SCNMaterial()
        pageMaterial.diffuse.contents = UIColor(white: 0.9, alpha: 1.0)
        
        // Tüm yüzeyler için materyal ata
        bookBox.materials = [spineMaterial, pageMaterial, coverMaterial, coverMaterial, pageMaterial, pageMaterial]
        
        let bookGeometryNode = SCNNode(geometry: bookBox)
        
        // Kitap pozisyonu
        let levelHeight: Float = Float(levelIndex) * 0.25
        let startX: Float = -shelfWidth/2 + 0.05 + Float(index) * (bookWidth + 0.01)
        let bookPositionY = levelHeight + bookHeight/2 + 0.02
        
        bookGeometryNode.position = SCNVector3(startX, bookPositionY, 0)
        
        // Kitaba metin ekle (başlık)
        let textNode = createBookTitleNode(title: book.title, bookWidth: bookWidth, bookHeight: bookHeight)
        bookGeometryNode.addChildNode(textNode)
        
        bookNode.addChildNode(bookGeometryNode)
        return bookNode
    }
    
    // Kitap başlığı düğümü oluşturma
    private func createBookTitleNode(title: String, bookWidth: Float, bookHeight: Float) -> SCNNode {
        let textNode = SCNNode()
        
        // Kitap sırtına başlığı ekliyoruz
        let text = SCNText(string: title, extrusionDepth: 0.001)
        text.font = UIFont.systemFont(ofSize: 1)
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        // Metni küçült
        let textScale: Float = min(0.01, bookWidth / Float(title.count) * 10)
        
        let textGeometryNode = SCNNode(geometry: text)
        textGeometryNode.scale = SCNVector3(textScale, textScale, textScale)
        
        // Metni kitap sırtına yerleştir
        textGeometryNode.eulerAngles = SCNVector3(0, GLKMathDegreesToRadians(90), 0)
        textGeometryNode.position = SCNVector3(-bookWidth/2 - 0.001, -0.03, 0)
        
        textNode.addChildNode(textGeometryNode)
        return textNode
    }
} 