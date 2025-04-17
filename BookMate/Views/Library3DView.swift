import SwiftUI
import SceneKit

struct Library3DView: View {
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @StateObject var library3DViewModel = Library3DViewModel()
    @State private var scene: SCNScene?
    @State private var isRotating = false
    @State private var currentRotationAngle: Float = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if library3DViewModel.isLoading {
                    LoadingView()
                } else if library3DViewModel.library3D.totalBooks == 0 {
                    EmptyLibraryView()
                } else {
                    // 3D Görünüm
                    ZStack {
                        SceneView(
                            scene: scene,
                            options: [.allowsCameraControl, .autoenablesDefaultLighting]
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { _ in
                                    isRotating = true
                                }
                                .onEnded { _ in
                                    isRotating = false
                                }
                        )
                        
                        // Bilgi kartı
                        VStack {
                            Spacer()
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Kitaplık İstatistikleri")
                                        .font(.headline)
                                    
                                    Text("Toplam Kitap: \(library3DViewModel.library3D.totalBooks)")
                                        .font(.subheadline)
                                    
                                    Text("Kapasite: \(library3DViewModel.library3D.totalCapacity)")
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    
                    // Görüntüleme modu seçici
                    DisplayModeSelector(
                        selectedMode: $library3DViewModel.selectedDisplayMode,
                        onModeSelected: { mode in
                            library3DViewModel.updateDisplayMode(to: mode)
                            updateScene()
                        }
                    )
                }
            }
            .navigationTitle("3D Kütüphanem")
            .navigationBarItems(
                trailing: Button(action: {
                    // İleri düzey seçenekleri göster
                }) {
                    Image(systemName: "slider.horizontal.3")
                }
            )
            .onAppear {
                loadLibrary()
            }
        }
    }
    
    private func loadLibrary() {
        library3DViewModel.loadLibrary(books: libraryViewModel.books)
        
        // SceneKit sahnesini yükle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            updateScene()
        }
    }
    
    private func updateScene() {
        // 3D sahneyi oluştur
        scene = library3DViewModel.createScene()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Kütüphane Yükleniyor...")
                .font(.headline)
        }
    }
}

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
            
            Text("Henüz tamamlanmış kitabınız yok")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Kitaplarınızı tamamladıkça 3D kütüphaneniz oluşacaktır")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: Text("Kütüphanem")) {
                Text("Kütüphaneme Git")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
}

struct DisplayModeSelector: View {
    @Binding var selectedMode: Library3D.DisplayMode
    var onModeSelected: (Library3D.DisplayMode) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Görüntüleme Modu")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Library3D.DisplayMode.allCases) { mode in
                        DisplayModeButton(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onTap: {
                                selectedMode = mode
                                onModeSelected(mode)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
}

struct DisplayModeButton: View {
    let mode: Library3D.DisplayMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var icon: String {
        switch mode {
        case .chronological:
            return "calendar"
        case .category:
            return "folder"
        case .author:
            return "person"
        case .color:
            return "paintpalette"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                
                Text(mode.rawValue)
                    .font(.caption)
            }
            .frame(width: 80, height: 70)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct Library3DView_Previews: PreviewProvider {
    static var previews: some View {
        Library3DView()
            .environmentObject(LibraryViewModel())
    }
} 