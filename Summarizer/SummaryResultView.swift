import SwiftUI

struct SummaryResultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showCopiedAlert = false
    @Binding var inputText: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.top)
                        
                        Text(appState.summaryResult ?? "")
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 15) {
                    Button(action: {
                        if let summary = appState.summaryResult {
                            UIPasteboard.general.string = summary
                            showCopiedAlert = true
                            
                            // Hide alert after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedAlert = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        appState.resetState()
                        inputText = ""
                        dismiss()
                    }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Summary Result")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                Group {
                    if showCopiedAlert {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Copied to clipboard!")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding(.bottom, 50)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut, value: showCopiedAlert)
                    }
                }
            )
        }
    }
}

#Preview {
    @Previewable @State var sample = ""
    
    SummaryResultView(inputText: $sample)
        .environmentObject({
            let state = AppState()
            state.summaryResult = "This is a sample summary of the provided text. The text has been analyzed and condensed to provide the key points and main ideas."
            return state
        }())
}
