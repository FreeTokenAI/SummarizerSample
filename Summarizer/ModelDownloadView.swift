import SwiftUI

struct ModelDownloadView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "cpu")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("AI Model Required")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("To summarize text locally on your device, you need to download the AI model.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .foregroundColor(.secondary)
                
                if appState.isDownloading {
                    VStack(spacing: 15) {
                        ProgressView(value: appState.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 250)
                        
                        Text("\(Int(appState.downloadProgress * 100))% downloaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    Button(action: {
                        Task {
                            await appState.downloadModel()
                        }
                    }) {
                        Text("Download Model")
                            .frame(width: 200)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Download AI Model")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                if !appState.isDownloading {
                    dismiss()
                }
            }
            .disabled(appState.isDownloading))
        }
    }
}

#Preview {
    ModelDownloadView()
        .environmentObject(AppState())
}
