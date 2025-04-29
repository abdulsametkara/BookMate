import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var navigateToRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Logo ve Başlık
                VStack(spacing: 15) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("BookMate")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Okuma yolculuğunuza hoş geldiniz")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Giriş formu
                VStack(spacing: 20) {
                    // E-posta alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("E-posta")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("E-posta adresiniz", text: $email)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Şifre alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifre")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            if showPassword {
                                TextField("Şifreniz", text: $password)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Şifreniz", text: $password)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 10)
                        }
                    }
                    
                    // Hata mesajı
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.vertical, 5)
                    }
                    
                    // Giriş yap butonu
                    Button(action: {
                        authViewModel.login(email: email, password: password)
                    }) {
                        HStack {
                            Text("Giriş Yap")
                                .fontWeight(.semibold)
                            
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.leading, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Kayıt ol bağlantısı
                    HStack {
                        Text("Hesabınız yok mu?")
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: RegisterView()) {
                            Text("Kayıt ol")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
} 