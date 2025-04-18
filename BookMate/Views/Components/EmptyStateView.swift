// EmptyStateView.swift
// BookMate
//
// Created for BookMate project
//

import SwiftUI

struct EmptyStateView: View {
    let message: String
    let buttonText: String?
    let icon: String
    let action: (() -> Void)?
    
    init(message: String, buttonText: String? = nil, icon: String, action: (() -> Void)? = nil) {
        self.message = message
        self.buttonText = buttonText
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .padding()
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let buttonText = buttonText, let action = action {
                Button(action: action) {
                    Text(buttonText)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(12)
    }
} 