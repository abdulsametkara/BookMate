import SwiftUI

// This extension file resolves ambiguities with ViewModel types
// by providing clear typealias declarations

// UserViewModel typealias
typealias AppUserViewModel = BookMate.UserViewModel

// Extension to avoid ambiguity in previews
extension View {
    func withViewModels() -> some View {
        self
            .environmentObject(BookViewModel())
            .environmentObject(AppUserViewModel())
    }
}