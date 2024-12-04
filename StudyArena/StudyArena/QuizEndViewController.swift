//
//  QuizEndViewController.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 12/1/24.
//

import UIKit
import FirebaseFirestore
import FirebaseDatabase

class QuizEndViewController: UIViewController {

    var ref: DatabaseReference!

    @IBOutlet weak var scoreLabel: UILabel! // Displays the final score
    //@IBOutlet weak var restartButton: UIButton! // Button to restart the quiz
    //@IBOutlet weak var mainMenuButton: UIButton! // Button to return to the main menu

    @IBOutlet weak var messageLabel: UILabel!
    var finalScore: Int = 0
    var totalQuestions: Int = 10
    var classData: ClassData?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scoreLabel.text = "\(finalScore*10)%"

        if finalScore == totalQuestions {
            messageLabel.text = "Perfect score! You're a genius!"
        } else if finalScore > totalQuestions / 2 {
            messageLabel.text = "Great job! Keep up the good work!"
        } else {
            messageLabel.text = "Good effort! Practice makes perfect!"
        }
        
        setHighScore(classID: classData!.id, newHighScore: finalScore)
    }
    
    func setHighScore(classID: String, newHighScore: Int) {
        
        if (classData?.highScore ?? 10 < newHighScore){
            
            let classRef = ref.child("classes").child(classID)
            
            classRef.updateChildValues(["highScore": newHighScore])
        }
        
    }
    
    func setAverageScore(classID: String, newScore: Int) {
            
            let classRef = ref.child("classes").child(classID)
            
            classRef.observeSingleEvent(of: .value) { snapshot in
                if let classData = snapshot.value as? [String: Any], let averageScore = classData["averageScore"] as? Int, let quizzesTaken = classData["quizzesTaken"] as? Int {
                    let newQuizzesTaken = quizzesTaken + 1
                    let newAverageScore = ((averageScore * quizzesTaken) + newScore) / newQuizzesTaken
                    
                    classRef.updateChildValues(["averageScore": newAverageScore])
                    classRef.updateChildValues(["quizzesTaken": newQuizzesTaken])
                }
            }
        }

    @IBAction func returnTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }


}
