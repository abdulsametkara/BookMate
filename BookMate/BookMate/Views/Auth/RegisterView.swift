import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var showPassword = false
    @State private var showPasswordConfirm = false
    
    // Yeni eklenen alanlar
    @State private var fullName = ""
    @State private var bio = ""
    @State private var navigateToLogin = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Başlık
                Text("Hesap Oluştur")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                // Kayıt formu
                VStack(spacing: 20) {
                    // Kullanıcı adı alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kullanıcı Adı")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Kullanıcı adınız", text: $username)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                    }
                    
                    // İsim Soyisim alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("İsim Soyisim")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("İsim ve soyisminiz", text: $fullName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.words)
                    }
                    
                    // Biyografi alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hakkınızda (opsiyonel)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Kendiniz hakkında kısa bilgi", text: $bio)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .frame(height: 80)
                    }
                    
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
                        
                        Text("En az 6 karakter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Şifre onay alanı
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifre Onayı")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            if showPasswordConfirm {
                                TextField("Şifrenizi tekrar girin", text: $passwordConfirm)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Şifrenizi tekrar girin", text: $passwordConfirm)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .autocapitalization(.none)
                            }
                            
                            Button(action: {
                                showPasswordConfirm.toggle()
                            }) {
                                Image(systemName: showPasswordConfirm ? "eye.slash.fill" : "eye.fill")
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
                    
                    // Kayıt ol butonu
                    Button(action: {
                        authViewModel.register(
                            username: username,
                            email: email,
                            password: password,
                            passwordConfirm: passwordConfirm,
                            fullName: fullName,
                            bio: bio
                        )
                    }) {
                        HStack {
                            Text("Kayıt Ol")
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
                    
                    // Giriş yap bağlantısı
                    HStack {
                        Text("Zaten hesabınız var mı?")
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Giriş yap")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationTitle("Hesap Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                // Kayıt başarılı olduğunda bir saniyelik gecikme ile giriş ekranına dön
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                    // İsteğe bağlı: Burada başarılı kayıt mesajı gösterilebilir
                }
            }
        }
    }
} 