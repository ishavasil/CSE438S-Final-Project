//
//  SelectCourseViewController.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 11/29/24.
//

import UIKit

class SelectCourseViewController: UIViewController {

    @IBOutlet weak var courseNameLabel: UILabel!
    var classData: ClassData? // Add this to hold the selected course data

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let data = classData {
            courseNameLabel.text = data.id
            
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
