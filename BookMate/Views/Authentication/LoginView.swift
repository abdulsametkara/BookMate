import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Logo ve başlık
                    VStack {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .padding(.bottom, 10)
                        
                        Text("BookMate")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Çiftler için Kitap Okuma Uygulaması")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                    
                    // Giriş formu
                    VStack(spacing: 20) {
                        TextField("E-posta", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        HStack {
                            if showingPassword {
                                TextField("Şifre", text: $password)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            } else {
                                SecureField("Şifre", text: $password)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showingPassword.toggle()
                            }) {
                                Image(systemName: showingPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(10)
                        
                        if let error = authManager.error {
                            Text(error.localizedDescription)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, -10)
                        }
                        
                        Button(action: {
                            authManager.login(email: email, password: password)
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Giriş Yap")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                        
                        Button(action: {
                            // Şifremi unuttum (gerçek uygulamada implemente edilir)
                        }) {
                            Text("Şifremi Unuttum")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Kayıt ol butonu
                    VStack {
                        Divider()
                            .padding(.vertical)
                        
                        Button(action: {
                            showingRegistration = true
                        }) {
                            Text("Hesabınız yok mu? Kayıt olun")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .sheet(isPresented: $showingRegistration) {
                RegistrationView()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 