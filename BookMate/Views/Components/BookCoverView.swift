// BookCoverView.swift
// BookMate
//
// Created for BookMate project
//

import SwiftUI

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Book cover
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.8))
                .overlay(
                    VStack {
                        Text(book.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                        
                        Text(book.author)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                )
                .shadow(radius: 4)
            
            // Status indicator
            if book.status == .reading {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(8)
            } else if book.status == .finished {
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(8)
            }
        }
    }
} 