//
//  SummarizerApp.swift
//  Summarizer
//
//  Created by Vince Francesi on 9/11/25.
//

import SwiftUI
import FreeToken

@main
struct SummarizerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await appState.initializeFreeToken()
                }
        }
    }
}
