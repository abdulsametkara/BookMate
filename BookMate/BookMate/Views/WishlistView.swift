import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var isAddingBook = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama çubuğu
                SearchBar(text: $searchText, placeholder: "Kitap ara...")
                    .padding(.horizontal)
                
                if filteredWishlist.isEmpty {
                    emptyWishlistView
                } else {
                    wishlistContent
                }
            }
            .navigationTitle("İstek Listem")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingBook = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingBook) {
                AddToWishlistView()
            }
        }
    }
    
    private var filteredWishlist: [Book] {
        if searchText.isEmpty {
            return bookViewModel.wishlistBooks
        } else {
            return bookViewModel.wishlistBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.authors.joined(separator: ", ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var wishlistContent: some View {
        List {
            ForEach(filteredWishlist) { book in
                WishlistBookRow(book: book)
            }
            .onDelete(perform: removeFromWishlist)
        }
    }
    
    private var emptyWishlistView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("İstek listenizde henüz kitap yok")
                .font(.headline)
            
            Text("Okumak istediğiniz kitapları buraya ekleyebilirsiniz")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                isAddingBook = true
            }) {
                Text("Kitap Ekle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func removeFromWishlist(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredWishlist[index]
            bookViewModel.removeFromWishlist(book)
        }
    }
}

struct WishlistBookRow: View {
    let book: Book
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Kitap kapağı
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    } else {
                        bookCoverPlaceholder
                    }
                }
                .frame(width: 60, height: 90)
            } else {
                bookCoverPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let price = book.price, let currency = book.currency {
                    Text("\(price) \(currency)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(5)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .padding(8)
                    .foregroundColor(.gray)
            }
            .confirmationDialog("Kitap İşlemleri", isPresented: $showingOptions) {
                Button("Kütüphaneye Ekle") {
                    bookViewModel.addToLibrary(book)
                    bookViewModel.removeFromWishlist(book)
                }
                
                Button("Detayları Görüntüle") {
                    // Detay sayfasına git
                }
                
                Button("Silmek İstiyorum", role: .destructive) {
                    bookViewModel.removeFromWishlist(book)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var bookCoverPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 90)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
            )
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddToWishlistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama çubuğu
                HStack {
                    TextField("Kitap ara...", text: $searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.trailing, 8)
                    
                    Button("Ara") {
                        if !searchText.isEmpty {
                            searchBooks()
                        }
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding(.horizontal)
                
                if isSearching {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("Sonuç bulunamadı")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(searchResults) { book in
                            HStack {
                                // Kitap bilgileri
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.headline)
                                    Text(book.authors.joined(separator: ", "))
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                                
                                // İstek listesine ekle butonu
                                if bookViewModel.isInWishlist(book) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                } else {
                                    Button(action: {
                                        bookViewModel.addToWishlist(book)
                                    }) {
                                        Image(systemName: "plus")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("İstek Listesine Ekle")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func searchBooks() {
        isSearching = true
        errorMessage = nil
        
        // Bu kısımda gerçek bir API çağrısı yapılacak
        // Şimdilik örnek olarak simüle ediyoruz
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Örnek arama sonuçları
            searchResults = Book.samples.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.authors.joined(separator: "").localizedCaseInsensitiveContains(searchText)
            }
            isSearching = false
        }
    }
}

#Preview {
    let bookVM = BookViewModel()
    return WishlistView()
        .environmentObject(bookVM)
} 