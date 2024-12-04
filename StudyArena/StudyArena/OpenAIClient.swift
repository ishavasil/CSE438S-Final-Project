import Foundation

class OpenAIService {
    
    
    private var apiKey = ""
    var thread = ""
    private var assistant = ""
    
    
    init() {
        apiKey = getAPIKey() ?? "error";
        assistant = getAssistant() ?? "error"
    }
    
    init(ThreadID: String) {
        apiKey = getAPIKey() ?? "error"
        assistant = getAssistant() ?? "error"
        self.thread = ThreadID
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
    
    func getAssistant() -> String? {
        guard let path = Bundle.main.path(forResource: "OpenAI", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["AssistantID"] as? String else {
            print("Assistant not found in OpenAI.plist")
            return nil
        }
        return apiKey
    }
    
    
    
    func createRun(threadID: String, assistantID: String) -> String {
        
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)/runs") else {
            fatalError("Invalid URL")
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        // Define the request body
        let requestBody: [String: Any] = [
            "assistant_id": assistantID,
            "model" : "gpt-4o-mini"
        ]

        // Serialize the request body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error serializing JSON: \(error)")
            return ""
        }

        // Fetch the Run ID synchronously
        var run: String? // Variable to store the result
        let semaphore = DispatchSemaphore(value: 0) // Semaphore to block and wait

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal() // Unblock the waiting thread
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                semaphore.signal()
                return
            }

            if !(200...299).contains(httpResponse.statusCode) {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("Response Body: \(responseBody)")
                }
                semaphore.signal()
                return
            }

            guard let data = data else {
                print("No data received")
                semaphore.signal()
                return
            }

            // Parse the response JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    run = json["id"] as? String
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }

            semaphore.signal() // Unblock the waiting thread
        }

        task.resume() // Start the task
        semaphore.wait() // Block the current thread until signal is called

        return run ?? "" // Return the result, or an empty string if nil
    }
    
    func fetchOpenAIResponse(ThreadId: String, run: String) -> QuizQuestion? {
        let statusUrl = URL(string: "https://api.openai.com/v1/threads/\(ThreadId)/runs/\(run)")!
        let messagesUrl = URL(string: "https://api.openai.com/v1/threads/\(ThreadId)/messages")!
        var result: QuizQuestion?
        let semaphore = DispatchSemaphore(value: 0)

        while true {
            var statusRequest = URLRequest(url: statusUrl)
            statusRequest.httpMethod = "GET"
            statusRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            statusRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

            let session = URLSession.shared
            session.dataTask(with: statusRequest) { data, response, error in
                if let error = error {
                    print("Error checking status: \(error.localizedDescription)")
                    semaphore.signal()
                    return
                }

                guard let data = data else {
                    print("No data received from status endpoint.")
                    semaphore.signal()
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let status = jsonResponse["status"] as? String {
                        print(status)
                        if status == "completed" {
                            var messagesRequest = URLRequest(url: messagesUrl)
                            messagesRequest.httpMethod = "GET"
                            messagesRequest.addValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                            messagesRequest.addValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

                            session.dataTask(with: messagesRequest) { data, response, error in
                                if let error = error {
                                    print("Error fetching messages: \(error.localizedDescription)")
                                    semaphore.signal()
                                    return
                                }

                                guard let data = data else {
                                    print("No data received from messages endpoint.")
                                    semaphore.signal()
                                    return
                                }

                                do {
                                    if let messagesResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                       let data = messagesResponse["data"] as? [[String: Any]],
                                       let firstItem = data.first,
                                       let content = firstItem["content"] as? [[String: Any]],
                                       let text = content.first?["text"] as? [String: Any],
                                       let rawValue = text["value"] as? String {
                                           
                                        // Clean the JSON string
                                        let cleanedValue = rawValue
                                            .replacingOccurrences(of: "```json", with: "")
                                            .replacingOccurrences(of: "```", with: "")
                                            .trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        // Decode the cleaned string into the QuizQuestion struct
                                        if let jsonData = cleanedValue.data(using: .utf8) {
                                            do {
                                                let decoder = JSONDecoder()
                                                let quizQuestion = try decoder.decode(QuizQuestion.self, from: jsonData)
                                                result = quizQuestion
                                            } catch {
                                                print("Failed to decode JSON into QuizQuestion: \(error)")
                                            }
                                        }
                                    }
                                } catch {
                                    print("Error decoding messages response: \(error.localizedDescription)")
                                }
                                semaphore.signal()
                            }.resume()
                            return
                        }
                    }
                } catch {
                    print("Error decoding status response: \(error.localizedDescription)")
                }
                semaphore.signal()
            }.resume()

            semaphore.wait()

            if result != nil {
                break
            }

            Thread.sleep(forTimeInterval: 1)
        }

        return result
    }
    
    func getQuestion() -> QuizQuestion {
        let nowRun = createRun(threadID: self.thread, assistantID: self.assistant)
        if let quizQuestion = fetchOpenAIResponse(ThreadId: self.thread, run: nowRun) {
            return quizQuestion
        }
        return QuizQuestion(question: "", option1: "", option2: "", option3: "", option4: "", correctOption: "")
    }
}
