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

    @IBOutlet weak var messageLabel: UILabel!
    var finalScore: Int = 0
    var totalQuestions: Int = 10

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
    }

    @IBAction func returnTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }


}
