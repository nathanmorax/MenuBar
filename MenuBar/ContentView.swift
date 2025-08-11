//
//  ContentView.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//

import SwiftUI


struct MenuItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
            Text(title)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct Separator: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.white.opacity(0.2))
            .padding(.horizontal, 8)
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Image(systemName: "iphone.gen1")
                    .resizable()
                    .frame(maxWidth: 12, maxHeight: 18)
                
                Text("MacRemote Classic")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            
            Separator()

            MenuItem(icon: "arrow.uturn.backward", title: "Undo")
            MenuItem(icon: "arrow.uturn.forward", title: "Redo")
            
            Separator()
            
            MenuItem(icon: "power", title: "Turn Off")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}


#Preview {
    ContentView()
}
