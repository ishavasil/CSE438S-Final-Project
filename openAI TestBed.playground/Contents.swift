import UIKit
import Foundation

class OpenAIHandler {
    // Global variables
    static var apiKey: String = "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"
    static var assistantID: String = "asst_R98EZmBJAJITwPBicjQhTaEx"
    
    // Member variables
    private var thread: String = ""
    private var vector: String = ""
    
    private init() {} // Private initializer to enforce use of async factory
        
    static func create(initialThreadID: String? = nil) async -> OpenAIHandler {
        let instance = OpenAIHandler()
        
        if let threadID = initialThreadID, await instance.isValidThread(threadID: threadID) {
            instance.thread = threadID
        } else if !instance.vector.isEmpty, await instance.isValidVector(vectorID: instance.vector) {
            await instance.createThread()
        } else {
            await instance.createVectorStore(name: "class documents")
            await instance.createThread()
        }
        
        return instance
    }
    
    // Create Vector Store
    func createVectorStore(name: String) async {
        guard let url = URL(string: "https://api.openai.com/v1/vector_stores") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = ["name": name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(VectorStoreResponse.self, from: data) {
                self.vector = response.id
            } else {
                print("Failed to decode the vector store response.")
            }
        } catch {
            print("Error creating vector store: \(error)")
        }
    }
    
    // Create Thread
    func createThread() async {
        guard let url = URL(string: "https://api.openai.com/v1/threads") else {
            print("Invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        guard let vectorID = self.vector as String? else {
            print("Vector ID is not set. Cannot create thread.")
            return
        }
        
        let body: [String: Any] = [
            "tool_resources": [
                "file_search": [
                    "vector_store_ids": [vectorID]
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }
            
            struct ThreadResponse: Codable {
                let id: String
            }
            
            if let decodedResponse = try? JSONDecoder().decode(ThreadResponse.self, from: data) {
                self.thread = decodedResponse.id
                print("Thread successfully created with ID: \(self.thread)")
            } else {
                print("Failed to decode the thread response.")
            }
            
        } catch {
            print("Error creating thread: \(error.localizedDescription)")
        }
    }
    
    // Send Message to Thread
    func sendMessageToThread(message: String) async {
        guard !self.thread.isEmpty, let url = URL(string: "https://api.openai.com/v1/threads/\(self.thread)/messages") else {
            print("Thread ID is not set or invalid URL.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = [
            "role": "user",
            "content": message
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Message Response: \(rawResponse)")
            }
            
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    // Get Question
    // Get Question
    func getQuestion() async -> [String: Any]? {
        guard !self.thread.isEmpty, let url = URL(string: "https://api.openai.com/v1/threads/\(self.thread)/runs") else {
            print("Thread ID is not set or invalid URL.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = [
            "assistant_id": OpenAIHandler.assistantID,
            "temperature": 1.0,
            "max_prompt_tokens": 1000,
            "max_completion_tokens": 1000,
            "response_format": "auto",
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponse)")
            }
            
            guard let initialResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let runID = initialResponse["id"] as? String else {
                print("Error: Unable to retrieve run ID.")
                return nil
            }
            
            var isCompleted = false
            var runData: [String: Any]?
            
            while !isCompleted {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                
                if let statusData = await checkRunStatus(runID: runID) {
                    if let status = statusData["status"] as? String, status == "completed" {
                        isCompleted = true
                        runData = statusData
                    } else {
                        print("Run is still in progress...")
                    }
                }
            }
            
            if let generatedResponse = runData?["response"] as? [String: Any] {
                return generatedResponse
            } else {
                print("Error: Generated response is not available.")
                return nil
            }
            
        } catch {
            print("Error executing the run: \(error.localizedDescription)")
            return nil
        }
    }


    func checkRunStatus(runID: String) async -> [String: Any]? {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(self.thread)/runs/\(runID)") else {
            print("Invalid URL for checking run status.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("Error checking run status: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func isValidThread(threadID: String) async -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               response["id"] as? String == threadID {
                return true
            }
        } catch {
            print("Error validating thread: \(error)")
        }
        return false
    }
    
    private func isValidVector(vectorID: String) async -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/vector_stores/\(vectorID)") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(OpenAIHandler.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               response["id"] as? String == vectorID {
                return true
            }
        } catch {
            print("Error validating vector: \(error)")
        }
        return false
    }
    
    struct VectorStoreResponse: Codable {
        let id: String
        let object: String
        let created_at: Int
    }
}

func testOpenAIHandler() async {
    // Use the factory method to create an instance of OpenAIHandler
    let handler = await OpenAIHandler.create(initialThreadID: nil)
    
    // Send a message first
    await handler.sendMessageToThread(message: "Hello, I need a question generated.")
    
    // Fetch and print the result of getQuestion
    if let result = await handler.getQuestion() {
        print("Run Response: \(result)")
    } else {
        print("Failed to get a valid response.")
    }
}

// Run the test
await testOpenAIHandler()
print("done")
