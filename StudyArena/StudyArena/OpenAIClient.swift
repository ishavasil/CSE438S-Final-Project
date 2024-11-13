import Foundation

class OpenAIService {
    
    
    private var apiKey = ""
    private let baseUrl = "https://api.openai.com/v1/assistants"
    
    
    init() {
        apiKey = getAPIKey() ?? "error";
    }

    func getAPIKey() -> String? {
        // get key from plist. Plist not pushed to protect api key
        guard let path = Bundle.main.path(forResource: "OpenAI", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["APIKey"] as? String else {
            print("API Key not found in OpenAI.plist")
            return nil
        }
        return apiKey
    }

    func sendMessageToAssistant(assistantId: String, completion: @escaping (String?) -> Void) {
        let message = "generate a question from the data in memory";
        let url = URL(string: "\(baseUrl)/\(assistantId)/message")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Request body parameters
        let parameters: [String: Any] = [
            "role": "user",
            "content": message
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error serializing request body: \(error)")
            completion(nil)
            return
        }
        
        // Create and resume the URLSession data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Check for errors in the network request
            if let error = error {
                print("Error sending message: \(error)")
                completion(nil)
                return
            }
            
            // Handle the response data
            guard let data = data else {
                print("No data received from response")
                completion(nil)
                return
            }
            
            // Parse the JSON response
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let messageContent = choices.first?["message"] as? String {
                    // Return the assistant's response
                    completion(messageContent)
                } else {
                    print("Invalid response format")
                    completion("Error: Invalid response format")
                }
            } catch {
                print("Error parsing response: \(error)")
                completion("Error: \(error.localizedDescription)")
            }
        }
        
        // Start the task
        task.resume()
    }
}
