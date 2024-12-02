//
//  AddCourseViewController.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 11/30/24.
//

import UIKit
import FirebaseDatabase


class AddCourseViewController: UIViewController, UIDocumentPickerDelegate {

    @IBOutlet weak var courseNameTextField: UITextField!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var addCourseButton: UIButton!

    var ref: DatabaseReference!
    var uploadedFiles: [String] = [] // Array to hold uploaded file names or URLs
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = Database.database().reference()
    }
    
    // MARK: - Upload File
    @IBAction func uploadFileTapped(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image, .plainText], asCopy: true)
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    // ONLY UPLOADS FILE NAMES:
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            print("Selected file: \(url.lastPathComponent)")
            uploadedFiles.append(url.lastPathComponent) // Store file name (or handle upload)
        }
    }
    
    // FOR UPLOADING ACTUAL FILES:
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        let storageRef = Storage.storage().reference()
//
//        for url in urls {
//            let fileName = url.lastPathComponent
//            let fileRef = storageRef.child("course_files/\(fileName)")
//
//            // Upload file to Firebase Storage
//            fileRef.putFile(from: url, metadata: nil) { metadata, error in
//                if let error = error {
//                    print("Error uploading file: \(error)")
//                    return
//                }
//
//                // Get download URL
//                fileRef.downloadURL { url, error in
//                    if let error = error {
//                        print("Error getting file URL: \(error)")
//                        return
//                    }
//
//                    if let fileURL = url?.absoluteString {
//                        print("Uploaded file URL: \(fileURL)")
//                        self.uploadedFiles.append(fileURL) // Store file URL in the database
//                    }
//                }
//            }
//        }
//    }


    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }

    // MARK: - Add Course
    @IBAction func addCourseTapped(_ sender: UIButton) {
        guard let courseName = courseNameTextField.text, !courseName.isEmpty else {
            showAlert(title: "Error", message: "Please enter a course name.")
            return
        }

        guard !uploadedFiles.isEmpty else {
            showAlert(title: "Error", message: "Please upload at least one file.")
            return
        }

        // Add class data to Firebase
        let newCourseID = courseName.replacingOccurrences(of: " ", with: "_").lowercased()
        addClassData(classID: newCourseID, assistant: "default_assistant", averageScore: 0, highScore: 0, lowScore: 0, quizzesTaken: 0)
    }

    // Add class data function
    func addClassData(classID: String, assistant: String, averageScore: Int, highScore: Int, lowScore: Int, quizzesTaken: Int) {
        let classData: [String: Any] = [
            "assistant": assistant,
            "averageScore": averageScore,
            "highScore": highScore,
            "lowScore": lowScore,
            "quizzesTaken": quizzesTaken,
            "uploadedFiles": uploadedFiles // Add file names/URLs to the database
        ]

        ref.child("classes").child(classID).setValue(classData) { error, _ in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to add course: \(error.localizedDescription)")
            } else {
                self.showAlert(title: "Success", message: "Course added successfully!") {
                    self.dismiss(animated: true, completion: nil) // Return to previous screen
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
