import SwiftUI

struct CollectionDetailView: View {
    @ObservedObject var viewModel: BookCollectionViewModel
    @State private var collection: BookCollection
    @State private var isEditingName = false
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var showingSortOptions = false
    @State private var showingFilterOptions = false
    @State private var showingAddBookSheet = false
    @State private var searchText = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    init(viewModel: BookCollectionViewModel, collectionId: String) {
        self.viewModel = viewModel
        
        // Get the collection from the view model
        guard let initialCollection = viewModel.getCollection(id: collectionId) else {
            fatalError("Collection not found")
        }
        
        // Initialize state
        _collection = State(initialValue: initialCollection)
        _newName = State(initialValue: initialCollection.name)
        _newDescription = State(initialValue: initialCollection.description ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collection header
            headerView
                .padding()
                .background(Color.blue.opacity(0.1))
            
            // Collection stats
            statsView
                .padding()
                .background(Color.gray.opacity(0.1))
            
            // Search field
            searchField
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Main content - book grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(filteredBooks) { book in
                        BookCardView(book: book)
                            .contextMenu {
                                Button(action: {
                                    viewModel.removeBookFromCollection(bookId: book.id, collectionId: collection.id)
                                }) {
                                    Label("Remove from Collection", systemImage: "minus.circle")
                                }
                                
                                if !book.isFavorite {
                                    Button(action: {
                                        // Mark as favorite
                                    }) {
                                        Label("Add to Favorites", systemImage: "heart")
                                    }
                                }
                            }
                    }
                }
                .padding()
            }
            
            // Empty state
            if collection.books.isEmpty {
                emptyStateView
            }
            
            Spacer()
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBookSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { isEditingName = true }) {
                        Label("Edit Collection", systemImage: "pencil")
                    }
                    
                    Button(action: { showingSortOptions = true }) {
                        Label("Sort Books", systemImage: "arrow.up.arrow.down")
                    }
                    
                    Button(action: { showingFilterOptions = true }) {
                        Label("Filter Books", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    
                    if !collection.isDefault {
                        Button(action: {
                            viewModel.toggleShareWithPartner(collectionId: collection.id)
                        }) {
                            Label(
                                collection.isSharedWithPartner ? "Unshare with Partner" : "Share with Partner",
                                systemImage: collection.isSharedWithPartner ? "person.badge.minus" : "person.badge.plus"
                            )
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            viewModel.deleteCollection(withId: collection.id)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Label("Delete Collection", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddBookSheet) {
            AddBooksToCollectionView(
                viewModel: viewModel,
                collectionId: collection.id
            )
        }
        .alert("Edit Collection", isPresented: $isEditingName) {
            TextField("Collection Name", text: $newName)
            TextField("Description (Optional)", text: $newDescription)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                viewModel.updateCollection(
                    id: collection.id,
                    name: newName,
                    description: newDescription.isEmpty ? nil : newDescription
                )
            }
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort Books"),
                buttons: sortActionButtons
            )
        }
        .actionSheet(isPresented: $showingFilterOptions) {
            ActionSheet(
                title: Text("Filter Books"),
                buttons: filterActionButtons
            )
        }
        .onAppear {
            // Refresh collection data
            if let refreshedCollection = viewModel.getCollection(id: collection.id) {
                collection = refreshedCollection
            }
        }
    }
    
    // MARK: - Component Views
    
    var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(collection.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let description = collection.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if collection.isSharedWithPartner {
                Label("Shared with Partner", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
    }
    
    var statsView: some View {
        HStack(spacing: 20) {
            StatView(title: "Books", value: "\(collection.bookCount)")
            StatView(title: "Pages", value: "\(collection.totalPages)")
            
            if collection.averageRating > 0 {
                StatView(title: "Rating", value: String(format: "%.1f", collection.averageRating))
            }
            
            if collection.completionPercentage > 0 {
                StatView(title: "Completed", value: "\(Int(collection.completionPercentage))%")
            }
        }
    }
    
    var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search in collection", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Books Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Tap + to add books to this collection")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddBookSheet = true }) {
                Text("Add Books")
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return viewModel.processedBooks(forCollectionId: collection.id)
        } else {
            return viewModel.processedBooks(forCollectionId: collection.id).filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                (book.authors?.joined(separator: ", ").localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var sortActionButtons: [ActionSheet.Button] {
        let sortOptions: [(SortOption, String, String)] = [
            (.title, "Title (A-Z)", "textformat.abc"),
            (.author, "Author (A-Z)", "person"),
            (.dateAdded, "Recently Added", "calendar"),
            (.publishedDate, "Publication Date", "calendar"),
            (.rating, "Rating", "star"),
            (.readingProgress, "Reading Progress", "book")
        ]
        
        var buttons = sortOptions.map { option, title, icon in
            ActionSheet.Button.default(Text("\(Image(systemName: icon)) \(title)")) {
                viewModel.setSortOption(option: option, collectionId: collection.id)
            }
        }
        
        buttons.append(.cancel())
        
        return buttons
    }
    
    var filterActionButtons: [ActionSheet.Button] {
        var buttons = [ActionSheet.Button]()
        
        // Reading status filters
        buttons.append(.default(Text("Currently Reading")) {
            viewModel.addFilterOption(option: .inProgress, collectionId: collection.id)
        })
        
        buttons.append(.default(Text("Completed")) {
            viewModel.addFilterOption(option: .completed, collectionId: collection.id)
        })
        
        buttons.append(.default(Text("Not Started")) {
            viewModel.addFilterOption(option: .unread, collectionId: collection.id)
        })
        
        // Other filters
        buttons.append(.default(Text("Favorites")) {
            viewModel.addFilterOption(option: .favorite, collectionId: collection.id)
        })
        
        buttons.append(.default(Text("Has Notes")) {
            viewModel.addFilterOption(option: .hasNotes, collectionId: collection.id)
        })
        
        // Clear filters
        if !collection.filterOptions.isEmpty {
            buttons.append(.destructive(Text("Clear All Filters")) {
                viewModel.clearFilterOptions(collectionId: collection.id)
            })
        }
        
        buttons.append(.cancel())
        
        return buttons
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct BookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            // Cover image
            ZStack {
                if let coverUrl = book.coverImageUrl {
                    AsyncImage(url: coverUrl) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(book.title.prefix(1).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        )
                }
                
                // Reading status badge
                VStack {
                    HStack {
                        Spacer()
                        
                        if book.readingStatus == .inProgress {
                            Text("\(Int(book.readingProgressPercentage))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(4)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        } else if book.readingStatus == .finished {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(4)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(4)
            }
            .frame(height: 160)
            .cornerRadius(8)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(book.authors?.joined(separator: ", ") ?? "Unknown Author")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Rating if available
                if let rating = book.userRating {
                    HStack(spacing: 0) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AddBooksToCollectionView: View {
    @ObservedObject var viewModel: BookCollectionViewModel
    let collectionId: String
    @State private var searchText = ""
    @State private var selectedBookIds = Set<String>()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for books", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                List {
                    ForEach(filteredBooks) { book in
                        HStack {
                            HStack(spacing: 12) {
                                // Cover image or placeholder
                                if let coverUrl = book.coverImageUrl {
                                    AsyncImage(url: coverUrl) { phase in
                                        switch phase {
                                        case .empty:
                                            Image(systemName: "book.closed")
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 70)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 70)
                                        case .failure:
                                            Image(systemName: "book.closed")
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 70)
                                        @unknown default:
                                            Image(systemName: "book.closed")
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 70)
                                        }
                                    }
                                } else {
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.gray)
                                        .frame(width: 50, height: 70)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.system(size: 16))
                                        .fontWeight(.medium)
                                    
                                    Text(book.authors?.joined(separator: ", ") ?? "Unknown Author")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Selection indicator
                            if isBookInCollection(book.id) {
                                Text("Added")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if selectedBookIds.contains(book.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isBookInCollection(book.id) {
                                if selectedBookIds.contains(book.id) {
                                    selectedBookIds.remove(book.id)
                                } else {
                                    selectedBookIds.insert(book.id)
                                }
                            }
                        }
                    }
                }
                
                // Add button
                if !selectedBookIds.isEmpty {
                    Button(action: {
                        addSelectedBooks()
                    }) {
                        Text("Add \(selectedBookIds.count) Books")
                            .fontWeight(.medium)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredBooks: [Book] {
        // This would typically come from a book service or view model
        // For now, just returning placeholder books
        return []
    }
    
    private func isBookInCollection(_ bookId: String) -> Bool {
        return viewModel.isBookInCollection(bookId: bookId, collectionId: collectionId)
    }
    
    private func addSelectedBooks() {
        for bookId in selectedBookIds {
            viewModel.addBookToCollection(book: dummyBook(id: bookId), collectionId: collectionId)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func dummyBook(id: String) -> Book {
        // This is just a placeholder. In a real app, you'd fetch the actual book object.
        return Book(
            id: id,
            title: "Book Title",
            authors: ["Author Name"],
            dateAdded: Date(),
            currentPage: 0,
            readingStatus: .notStarted
        )
    }
}

struct CollectionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CollectionDetailView(
                viewModel: BookCollectionViewModel.preview,
                collectionId: "preview-collection"
            )
        }
    }
} 