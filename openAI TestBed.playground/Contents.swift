import UIKit

let apiKey = "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"

class chatbot {
    var id:String
    var files:String
    
    init(id: String, files:String) {
        self.id = id
        self.files = files
    }
    
    init() {
        //add code here for creating a new assistant
        self.id = ""
        self.files = ""
    }
    
    func getId() -> String {
        return self.id
    }
    
    func createThread(completion: @escaping (Result<String, Error>) -> Void) {
            // Endpoint URL
            guard let url = URL(string: "https://api.openai.com/v1/threads") else {
                completion(.failure(NSError(domain: "Invalid URL", code: 1, userInfo: nil)))
                return
            }
            
            // Prepare the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
            request.httpBody = "{}".data(using: .utf8) // Empty body as per the cURL
            
            // Make the network request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Handle errors
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Ensure data exists
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: 2, userInfo: nil)))
                    return
                }
                
                // Parse the response JSON
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let threadId = jsonResponse["id"] as? String {
                        completion(.success(threadId))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response format", code: 3, userInfo: nil)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
    
}

let b = chatbot(id: "asst_R98EZmBJAJITwPBicjQhTaEx", files: "vs_k7JHyIqZmYDlXOMVNQex9pT9")

b.createThread { result in
    switch result {
    case .success(let threadId):
        print("Created thread with ID: \(threadId)")
    case .failure(let error):
        print("Failed to create thread: \(error)")
    }
}


