//
//  MenuBarApp.swift
//  MenuBar
//
//  Created by Jonathan Mora on 10/08/25.
//
import SwiftUI

@main
struct MacApp: App {
    let bonjourService = BonjourService()
    
    init() {
        bonjourService.start()
    }
    
    var body: some Scene {
        MenuBarExtra("Menu Bar Example", systemImage: "iphone.gen1") {
            ContentView()
                .frame(width: 260, height: 160)
        }
        .menuBarExtraStyle(.window)
    }
}

