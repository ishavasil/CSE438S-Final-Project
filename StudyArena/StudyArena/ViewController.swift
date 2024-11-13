//
//  ViewController.swift
//  StudyArena
//
//  Created by Isha Vasil on 11/6/24.
//

import UIKit
import FirebaseFirestore
import FirebaseDatabase

class ViewController: UIViewController {
    
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        fetchClassesData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addClassData(classID: "cse131", assistant: "131Assistant", averageScore: 14, highScore: 15, lowScore: 13, quizzesTaken: 10)
        }
        
    }
    
    func fetchClassesData() {
        let classesRef = ref.child("classes")

        classesRef.observeSingleEvent(of: .value) { snapshot in
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let classData = childSnapshot.value as? [String: Any] {
                    
                    let classID = childSnapshot.key
                    print("Class ID: \(classID)")
                    
                    let assistant = classData["assistant"] as? String ?? "N/A"
                    let averageScore = classData["averageScore"] as? Int ?? 0
                    let highScore = classData["highScore"] as? Int ?? 0
                    let lowScore = classData["lowScore"] as? Int ?? 0
                    let quizzesTaken = classData["quizzesTaken"] as? Int ?? 0

                    print("Assistant: \(assistant)")
                    print("Average Score: \(averageScore)")
                    print("High Score: \(highScore)")
                    print("Low Score: \(lowScore)")
                    print("Quizzes Taken: \(quizzesTaken)")
                    print()
                }
            }
        }
    }
    
    
    func addClassData(classID: String, assistant: String, averageScore: Int, highScore: Int, lowScore: Int, quizzesTaken: Int) {
        let classData: [String: Any] = [
            "assistant": assistant,
            "averageScore": averageScore,
            "highScore": highScore,
            "lowScore": lowScore,
            "quizzesTaken": quizzesTaken
        ]
        
        ref.child("classes").child(classID).setValue(classData) { error, _ in
            if let error = error {
                print("Error adding class data: \(error)")
            } else {
                print("-------------")
                print("Class data added successfully!")
                self.fetchClassesData()
            }
        }
    }

}

