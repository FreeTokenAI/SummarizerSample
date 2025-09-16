import Foundation
import FreeToken
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isRegistered = false
    @Published var registrationError: String?
    @Published var isModelDownloaded = false
    @Published var downloadProgress: Double = 0.0
    @Published var isDownloading = false
    @Published var messageThreadId: String?
    @Published var isSummarizing = false
    @Published var summaryResult: String?
    @Published var errorMessage: String?
    @Published var showDownloadModal = false
    @Published var showResultModal = false
    @Published var tokenCount: Int = 0
    @Published var runLocation: String = ""
    
    private let client = FreeToken.shared
    private let appToken = "[YOUR APP TOKEN HERE]" // Replace with your actual app token
    private var runID: String = UUID().uuidString
    
    func initializeFreeToken() async {
        do {
            _ = try client.configure(
                appToken: appToken
            )
            isInitialized = true
            await registerDevice()
        } catch {
            errorMessage = "Failed to configure FreeToken: \(error.localizedDescription)"
        }
    }
    
    func registerDevice() async {
        await client.registerDeviceSession(
            scope: "summarizer",
            success: {
                await MainActor.run {
                    self.isRegistered = true
                }
                await self.checkModelDownloaded()
            },
            error: { error in
                await MainActor.run {
                    self.registrationError = "Registration failed: \(error.localizedDescription)"
                    self.errorMessage = "Failed to register device: \(error.localizedDescription)"
                }
            }
        )
    }
    
    func checkModelDownloaded() async {
        do {
            let state = try await client.getAIModelDownloadState()
            await MainActor.run {
                self.isModelDownloaded = (state == .downloaded)
                if !self.isModelDownloaded {
                    self.showDownloadModal = true
                } else {
                    Task {
                        await self.client.prewarmAIFor(runIdentifier: self.runID)
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check model status: \(error.localizedDescription)"
            }
        }
    }
    
    func downloadModel() async {
        isDownloading = true
        downloadProgress = 0.0
        
        await client.downloadAIModel(
            success: { state in
                await MainActor.run {
                    self.isDownloading = false
                    self.isModelDownloaded = true
                    self.showDownloadModal = false
                }
                
                await self.client.prewarmAIFor(runIdentifier: self.runID)
            },
            error: { error in
                await MainActor.run {
                    self.isDownloading = false
                    self.errorMessage = "Failed to download model: \(error.localizedDescription)"
                }
            },
            progressPercent: { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
        )
    }
    
    func summarizeText(_ text: String) async {
        guard !text.isEmpty else {
            errorMessage = "Please enter some text to summarize"
            return
        }
        
        resetState()
        isSummarizing = true
        
        do {
            // Create message thread
            await createMessageThread()
            
            guard let threadId = messageThreadId else {
                throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create message thread"])
            }
            
            // Count tokens
            let tokenCount = try await countTokens(text)
            
            // Determine run location based on token count
            let runLocation: FreeToken.RunLocation = tokenCount > 15000 ? .cloudRun : .localRun
            
            if tokenCount > 9999000 { // Llama Scout has a 10,000,000 token context - leave some extra room for generation
                throw NSError(domain: "AppState", code: 2, userInfo: [NSLocalizedDescriptionKey: "Content is too long to summarize"])
            }
            
            if runLocation == .cloudRun {
                await MainActor.run {
                    self.runLocation = "Cloud"
                }
            } else {
                await MainActor.run {
                    self.runLocation = "Local"
                }
            }
            
            // Add message to thread
            let message = FreeToken.Message(
                role: .user,
                content: "Summarize: \(text)"
            )
            
            await client.addMessageToThread(
                id: threadId,
                message: message,
                success: { _ in
                    // Run the thread either locally or in the cloud (based on runLocation)
                    await self.runThread(threadId: threadId, runLocation: runLocation)
                },
                error: { error in
                    await MainActor.run {
                        self.isSummarizing = false
                        self.errorMessage = "Failed to add message: \(error.localizedDescription)"
                    }
                }
            )
        } catch {
            await MainActor.run {
                isSummarizing = false
                errorMessage = "Failed to process text: \(error.localizedDescription)"
            }
        }
    }
    
    func countTokens(_ input: String) async throws -> Int {
        let tokenCount = try await client.countTokens(text: input)
        print("Token Count: \(tokenCount)")
        self.tokenCount = tokenCount
        return tokenCount
    }
    
    func resetState() {
        tokenCount = 0
        runLocation = ""
        isSummarizing = false
        errorMessage = nil
        summaryResult = ""
        runID = UUID().uuidString
        if let messageThreadID = messageThreadId {
            deleteMessageThread(threadID: messageThreadID)
            messageThreadId = nil
        }
    }
    
    private func createMessageThread() async {
        await client.createMessageThread(
            success: { thread in
                await MainActor.run {
                    self.messageThreadId = thread.id
                }
            },
            error: { error in
                await MainActor.run {
                    self.errorMessage = "Failed to create thread: \(error.localizedDescription)"
                }
            }
        )
    }
    
    private func deleteMessageThread(threadID: String) {
        client.deleteMessageThread(id: threadID) { id in
            print("Thread deleted successfully")
        } error: { error in
            print("Thread \(threadID) could not be deleted: \(error.localizedDescription)")
        }

    }
    
    private func runThread(threadId: String, runLocation: FreeToken.RunLocation) async {
        var modelCode: String? = nil
        
        if runLocation == .cloudRun {
            modelCode = "llama_4_scout_cloud" // Code found on app.freetoken.ai/ai_models
        }
        
        await client.runMessageThread(
            id: threadId,
            runLocation: runLocation,
            runIdentifier: self.runID,
            modelCode: modelCode,
            success: { resultMessage in
                
                await MainActor.run {
                    self.summaryResult = resultMessage.content
                    self.isSummarizing = false
                }
            },
            error: { error in
                await MainActor.run {
                    self.isSummarizing = false
                    self.errorMessage = "Summarization failed: \(error.localizedDescription)"
                }
            },
            chatStatusStream: { token, status in
                await MainActor.run {
                    if let token = token {
                        if self.showResultModal != true {
                            self.showResultModal = true
                        }
                        
                        if self.summaryResult == nil {
                            self.summaryResult = ""
                        }
                        self.summaryResult! += token
                    }
                }
            })
    }
}
