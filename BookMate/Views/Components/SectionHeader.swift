// SectionHeader.swift
// BookMate
//
// Created for BookMate project
//

import SwiftUI

struct SectionHeader<Destination: View>: View {
    let title: String
    let showAll: Bool
    let destination: Destination
    
    init(title: String, showAll: Bool = false, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.showAll = showAll
        self.destination = destination()
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            Spacer()
            
            if showAll {
                NavigationLink(destination: destination) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
} 