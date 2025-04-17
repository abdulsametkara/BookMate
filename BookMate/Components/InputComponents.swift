import SwiftUI

struct RoundedTextField: View {
    var title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var disableAutocorrection: Bool = false
    var icon: String? = nil
    var backgroundColor: Color = Color(.systemGray6)
    var textColor: Color = .primary
    var placeholderColor: Color = .gray
    var showClearButton: Bool = true
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundColor(placeholderColor)
                }
                
                TextField("", text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
                    .disableAutocorrection(disableAutocorrection)
                    .foregroundColor(textColor)
            }
            
            if showClearButton && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

struct RoundedSecureField: View {
    var title: String
    @Binding var text: String
    @State private var isSecured: Bool = true
    var icon: String? = nil
    var backgroundColor: Color = Color(.systemGray6)
    var textColor: Color = .primary
    var placeholderColor: Color = .gray
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
            }
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(title)
                        .foregroundColor(placeholderColor)
                }
                
                if isSecured {
                    SecureField("", text: $text)
                        .foregroundColor(textColor)
                } else {
                    TextField("", text: $text)
                        .foregroundColor(textColor)
                }
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye" : "eye.slash")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Ara..."
    var onCommit: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text, onCommit: {
                onCommit?()
            })
            .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onCancel?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct RatingSelector: View {
    @Binding var rating: Double
    var maxRating: Int = 5
    var iconSize: CGFloat = 24
    var spacing: CGFloat = 4
    var activeColor: Color = .yellow
    var inactiveColor: Color = .gray.opacity(0.3)
    var allowZeroRating: Bool = true
    var onChange: ((Double) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(rating >= Double(index) ? activeColor : inactiveColor)
                    .onTapGesture {
                        if rating == Double(index) && allowZeroRating {
                            rating = 0
                        } else {
                            rating = Double(index)
                        }
                        onChange?(rating)
                    }
            }
        }
    }
}

struct NumberStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100
    var step: Int = 1
    var backgroundColor: Color = Color(.systemGray6)
    var buttonColor: Color = .blue
    
    var body: some View {
        HStack {
            Button(action: {
                if value > range.lowerBound {
                    value = max(range.lowerBound, value - step)
                }
            }) {
                Image(systemName: "minus")
                    .font(.headline)
                    .foregroundColor(value > range.lowerBound ? buttonColor : .gray)
                    .frame(width: 44, height: 44)
                    .background(backgroundColor)
                    .cornerRadius(8)
            }
            .disabled(value <= range.lowerBound)
            
            Text("\(value)")
                .font(.headline)
                .frame(minWidth: 60)
                .padding(.horizontal, 8)
            
            Button(action: {
                if value < range.upperBound {
                    value = min(range.upperBound, value + step)
                }
            }) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundColor(value < range.upperBound ? buttonColor : .gray)
                    .frame(width: 44, height: 44)
                    .background(backgroundColor)
                    .cornerRadius(8)
            }
            .disabled(value >= range.upperBound)
        }
    }
}

struct SelectorBar<T: Hashable & CustomStringConvertible>: View {
    let options: [T]
    @Binding var selectedOption: T
    var font: Font = .subheadline
    var spacing: CGFloat = 16
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(options, id: \.self) { option in
                    VStack(spacing: 8) {
                        Text(option.description)
                            .font(font)
                            .fontWeight(selectedOption == option ? .semibold : .regular)
                            .foregroundColor(selectedOption == option ? .primary : .secondary)
                        
                        if selectedOption == option {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .fixedSize()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            selectedOption = option
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FormSectionHeader: View {
    var title: String
    var icon: String? = nil
    var description: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 6)
    }
}

#Preview {
    VStack(spacing: 20) {
        Group {
            @State var text1 = ""
            @State var text2 = "user@example.com"
            @State var password = "password123"
            @State var searchText = "1984"
            @State var rating = 3.5
            @State var numberOfPages = 42
            @State var selectedOption = "Hepsi"
            
            RoundedTextField(title: "Kullanıcı Adı", text: $text1, icon: "person")
            
            RoundedTextField(title: "E-posta", text: $text2, keyboardType: .emailAddress, icon: "envelope")
            
            RoundedSecureField(title: "Şifre", text: $password, icon: "lock")
            
            SearchBar(text: $searchText, placeholder: "Kitap veya yazar ara...")
            
            RatingSelector(rating: $rating)
            
            NumberStepper(value: $numberOfPages, range: 1...1000)
            
            SelectorBar(
                options: ["Hepsi", "Okunanlar", "Biten Kitaplar", "Başlanmayanlar", "Favoriler"],
                selectedOption: $selectedOption
            )
            
            FormSectionHeader(
                title: "Kişisel Bilgiler",
                icon: "person.circle",
                description: "Bu bilgiler profilinizde gösterilecektir."
            )
        }
    }
    .padding()
} 