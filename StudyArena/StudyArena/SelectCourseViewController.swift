//
//  SelectCourseViewController.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 11/29/24.
//

import UIKit

class SelectCourseViewController: UIViewController {

    
    @IBOutlet weak var takeQuiz: UIButton!
    @IBOutlet weak var courseNameLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var classTopScore: UILabel!
    @IBOutlet weak var classAvgScore: UILabel!
    var classData: ClassData? 

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let data = classData {
            print("viewDidLoad: \(data.id)") // Debugging
            courseNameLabel.text = data.id
            classTopScore.text = "Class Top Score: \(data.highScore)%"
            classAvgScore.text = "Class Avg Score: \(data.averageScore)%"
        } else {
            print("viewDidLoad: classData is nil")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQuizStart" {
            
            if let navigationController = segue.destination as? UINavigationController {
                // Get the top view controller from the navigation controller stack
                if let quizVC = navigationController.topViewController as? QuizViewController {
                    quizVC.classData = self.classData
                    print("Passing data: \(String(describing: self.classData))") // Debugging
                }
            }
        }
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
