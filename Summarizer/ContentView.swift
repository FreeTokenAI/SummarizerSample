//
//  ContentView.swift
//  Summarizer
//
//  Created by Vince Francesi on 9/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText = ""
    
    var body: some View {
        ZStack {
            if appState.isRegistered {
                SummarizerView(inputText: $inputText)
                    .environmentObject(appState)
            } else if appState.isInitialized {
                ProgressView("Registering device...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ProgressView("Initializing...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .sheet(isPresented: $appState.showDownloadModal) {
            ModelDownloadView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showResultModal) {
            SummaryResultView(inputText: $inputText)
                .environmentObject(appState)
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
