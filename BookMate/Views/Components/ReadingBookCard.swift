// ReadingBookCard.swift
// BookMate
//
// Created for BookMate project
//

import SwiftUI

struct ReadingBookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover
            BookCoverView(book: book)
                .frame(width: 80, height: 120)
            
            // Book info
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(book.currentPage)/\(book.pageCount) sayfa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(book.progressPercentage))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    ProgressBar(value: book.progressPercentage/100)
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProgressBar: View {
    var value: Double // 0.0 to 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .foregroundColor(Color.gray.opacity(0.2))
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(.blue)
                    .animation(.linear, value: value)
            }
        }
    }
} 