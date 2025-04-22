import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
            
            if authViewModel.isLoading {
                LoadingView()
            }
        }
        .alert(isPresented: .constant(authViewModel.errorMessage != nil), content: {
            Alert(
                title: Text("Hata"),
                message: Text(authViewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"),
                dismissButton: .default(Text("Tamam")) {
                    authViewModel.errorMessage = nil
                }
            )
        })
    }
}

// Ana gezinme için tab görünümü
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
            
            MyLibraryView()
                .tabItem {
                    Label("Kitaplığım", systemImage: "books.vertical")
                }
            
            ReadingTimerView()
                .tabItem {
                    Label("Zamanlayıcı", systemImage: "timer")
                }
            
            BookshelfView()
                .tabItem {
                    Label("3D Kitaplık", systemImage: "cube")
                }
            
            CoupleView()
                .tabItem {
                    Label("Eşleşme", systemImage: "person.2")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
        }
    }
}

// Kimlik doğrulama görünümü
struct AuthView: View {
    @State private var isSignIn = true
    
    var body: some View {
        VStack {
            // Logo
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("BookMate")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            if isSignIn {
                SignInView()
            } else {
                SignUpView()
            }
            
            Button(action: {
                isSignIn.toggle()
            }) {
                Text(isSignIn ? "Hesabınız yok mu? Kayıt olun" : "Hesabınız var mı? Giriş yapın")
                    .foregroundColor(.blue)
                    .padding(.top, 20)
            }
        }
        .padding(.horizontal, 20)
    }
}

// Giriş formu
struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("E-posta", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            SecureField("Şifre", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Button(action: {
                Task {
                    await authViewModel.signIn(email: email, password: password)
                }
            }) {
                Text("Giriş Yap")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
}

// Kayıt formu
struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Ad Soyad", text: $name)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            TextField("E-posta", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            SecureField("Şifre", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            SecureField("Şifreyi Onayla", text: $confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Button(action: {
                if password == confirmPassword {
                    Task {
                        await authViewModel.signUp(name: name, email: email, password: password)
                    }
                }
            }) {
                Text("Kayıt Ol")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(password != confirmPassword)
        }
    }
}

// Yükleniyor görünümü
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Yükleniyor...")
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
            .padding()
            .background(Color.gray.opacity(0.7))
            .cornerRadius(10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
} 