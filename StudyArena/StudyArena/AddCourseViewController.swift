import UIKit
import FirebaseDatabase

class AddCourseViewController: UIViewController, UIDocumentPickerDelegate {

    @IBOutlet weak var courseNameTextField: UITextField!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var addCourseButton: UIButton!

    var ref: DatabaseReference!
    var uploadedFiles: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
    }
    
    @IBAction func uploadFileTapped(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .plainText], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "OpenAI", ofType: "plist"),
              let dictionary = NSDictionary(contentsOfFile: path),
              let apiKey = dictionary["APIKey"] as? String else {
            print("API Key not found in OpenAI.plist")
            return nil
        }
        return apiKey
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let apiKey = getAPIKey() else {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: "Unable to retrieve API key")
            }
            return
        }
        
        let apiUrl = URL(string: "https://api.openai.com/v1/files")!
        let allowedFileTypes: [String] = [
            "image/jpeg",
            "image/png",
            "image/gif",
            "application/pdf",
            "text/plain",
            "text/csv",
            "text/markdown",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        ]
        let maxFileSize = 512 * 1024 * 1024  // 512 MB
        
        let uploadGroup = DispatchGroup()
        
        for url in urls {
            guard let fileData = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Could not read file data")
                }
                continue
            }
            
            // Validate file size
            guard fileData.count <= maxFileSize else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "File is too large. Maximum allowed size is 512 MB.")
                }
                continue
            }
            
            // Validate file type
            let fileType = mimeType(for: url)
            guard allowedFileTypes.contains(fileType) else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "File type not allowed.")
                }
                continue
            }
            
            // Prepare multipart form data
            var request = URLRequest(url: apiUrl)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(url.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(fileType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"purpose\"\r\n\r\n".data(using: .utf8)!)
            body.append("assistants\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            uploadGroup.enter()
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                defer { uploadGroup.leave() }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Upload Error", message: error.localizedDescription)
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: "No data received")
                    }
                    return
                }
                
                do {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw Response: \(responseString)")
                    }
                    let jsonResponse = try JSONDecoder().decode(OpenAIFileResponse.self, from: data)
                    DispatchQueue.main.async {
                        self?.uploadedFiles.append(jsonResponse.id)
                    }
                } catch {
                    print("Decoding Error: \(error)")
                    print("Decoding Error Description: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: "Failed to parse response: \(error.localizedDescription)")
                    }
                }
            }
            
            task.resume()
        }
        
        uploadGroup.notify(queue: .main) {
            print("All files processed")
        }
    }

    // OpenAI File Response Structure
    struct OpenAIFileResponse: Codable {
        let id: String
        let object: String
        let bytes: Int
        let created_at: Int
        let filename: String
        let purpose: String
    }
    
    // MIME Type Helper
    func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }

    @IBAction func addCourseTapped(_ sender: UIButton) {
        guard let courseName = courseNameTextField.text, !courseName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a course name.")
            return
        }

        guard !uploadedFiles.isEmpty else {
            showAlert(title: "Error", message: "Please upload at least one file.")
            return
        }

        let newCourseID = courseName.replacingOccurrences(of: " ", with: "_").lowercased()
        addClassData(classID: newCourseID, uploadedFiles: uploadedFiles)
    }

    // Simplified add class data function
    func addClassData(classID: String, uploadedFiles: [String]) {
        let classData: [String: Any] = [
            "assistant": "default_assistant",
            "uploadedFiles": uploadedFiles
        ]

        ref.child("classes").child(classID).setValue(classData) { error, _ in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to add course: \(error.localizedDescription)")
            } else {
                self.showAlert(title: "Success", message: "Course added successfully!") {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }

    // Helper: Show Alert
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true, completion: nil)
    }
}
