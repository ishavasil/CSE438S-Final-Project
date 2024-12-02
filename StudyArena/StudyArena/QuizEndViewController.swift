//
//  QuizEndViewController.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 12/1/24.
//

import UIKit

class QuizEndViewController: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel! // Displays the final score
    //@IBOutlet weak var restartButton: UIButton! // Button to restart the quiz
    //@IBOutlet weak var mainMenuButton: UIButton! // Button to return to the main menu

    var finalScore: Int = 0 // The score passed from QuizViewController
    var totalQuestions: Int = 0 // Total number of questions in the quiz

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the score label
        scoreLabel.text = "Your Score: \(finalScore) / \(totalQuestions)"

    }
//
//    // Restart the quiz
//    @IBAction func restartQuizTapped(_ sender: UIButton) {
//        navigationController?.popToRootViewController(animated: true)
//    }
//
//    // Return to the main menu
//    @IBAction func mainMenuTapped(_ sender: UIButton) {
//        // Navigate back to the main menu
//        navigationController?.popToRootViewController(animated: true)
//    }
}
