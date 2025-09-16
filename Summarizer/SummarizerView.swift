import SwiftUI

struct SummarizerView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isTextFieldFocused: Bool
    @Binding var inputText: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter text to summarize")
                    .font(.headline)
                    .padding(.top, 20)
                
                GeometryReader { geometry in
                    ScrollView {
                        TextEditor(text: $inputText)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .frame(height: geometry.size.height - 55)
                            .padding(.horizontal)
                            .onChange(of: inputText) { oldValue, newValue in
                                Task {
                                    try await appState.countTokens(inputText)
                                }
                            }
                        Text("Token Count: \(appState.tokenCount)")
                        Text("Run Location: \(appState.runLocation)")
                    }
                }
                
                Button(action: {
                    isTextFieldFocused = false
                    Task {
                        await appState.summarizeText(inputText)
                    }
                }) {
                    if appState.isSummarizing {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                            Text("Summarizing...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Text("Summarize")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputText.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(inputText.isEmpty || appState.isSummarizing)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("AI Summarizer")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    @Previewable @State var sample = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    SummarizerView(inputText: $sample)
        .environmentObject(AppState())
}
