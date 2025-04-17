import SwiftUI

struct RegistrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var agreedToTerms = false
    
    @State private var passwordError: String?
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && 
        password == confirmPassword && password.count >= 6 && agreedToTerms
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan
                Color(.systemGray6)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Başlık
                        Text("Yeni Hesap Oluştur")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        // Kayıt formu
                        VStack(spacing: 15) {
                            TextField("Adınız", text: $name)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .disableAutocorrection(true)
                            
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
                                        .onChange(of: password) { newValue in
                                            validatePassword()
                                        }
                                } else {
                                    SecureField("Şifre", text: $password)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .onChange(of: password) { newValue in
                                            validatePassword()
                                        }
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
                            
                            if let passwordError = passwordError {
                                Text(passwordError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 5)
                            }
                            
                            SecureField("Şifre (Tekrar)", text: $confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .onChange(of: confirmPassword) { newValue in
                                    validatePassword()
                                }
                            
                            // Kullanım şartları
                            Toggle(isOn: $agreedToTerms) {
                                Text("Kullanım Şartlarını kabul ediyorum")
                                    .font(.footnote)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .padding(.vertical, 5)
                            
                            if let error = authManager.error {
                                Text(error.localizedDescription)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                            
                            // Kayıt butonu
                            Button(action: {
                                register()
                            }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Kayıt Ol")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(!isFormValid || authManager.isLoading)
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.blue)
                }
            )
            .onReceive(authManager.$isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func validatePassword() {
        // Şifre doğrulama mantığı
        if password.isEmpty {
            passwordError = nil
            return
        }
        
        if password.count < 6 {
            passwordError = "Şifre en az 6 karakter olmalıdır."
            return
        }
        
        if !confirmPassword.isEmpty && password != confirmPassword {
            passwordError = "Şifreler eşleşmiyor."
            return
        }
        
        passwordError = nil
    }
    
    private func register() {
        authManager.register(name: name, email: email, password: password)
    }
}

// Özel bir toggle stili
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
} 