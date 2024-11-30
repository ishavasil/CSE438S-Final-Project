//
//  ViewController.swift
//  StudyArena
//
//  Created by Isha Vasil on 11/6/24.
//

import UIKit
import FirebaseFirestore
import FirebaseDatabase

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    
    @IBOutlet weak var classesCollectionView: UICollectionView!
    var ref: DatabaseReference!
    var classes: [ClassData] = [] // Array to hold fetched class data
    
    let ai = OpenAIService()
    
    
    var assistantID:String = "";
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        setupCollectionView()
        fetchClassesData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addClassData(classID: "cse131", assistant: "asst_R98EZmBJAJITwPBicjQhTaEx", averageScore: 14, highScore: 15, lowScore: 13, quizzesTaken: 10)
        }
        
        ai.sendMessageToAssistant(assistantId: assistantID) { response in
            print(response ?? "no message recieved");
        }
        
    }
    
    func fetchClassesData() {
        let classesRef = ref.child("classes")
        
        classesRef.observeSingleEvent(of: .value) { snapshot in
            var fetchedClasses: [ClassData] = []
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
                    
                    self.assistantID = assistant;
                    let classObject = ClassData(
                        id: classID,
                        assistant: assistant,
                        averageScore: averageScore,
                        highScore: highScore,
                        lowScore: lowScore,
                        quizzesTaken: quizzesTaken
                    )
                    fetchedClasses.append(classObject)
                    print("Assistant: \(assistant)")
                    print("Average Score: \(averageScore)")
                    print("High Score: \(highScore)")
                    print("Low Score: \(lowScore)")
                    print("Quizzes Taken: \(quizzesTaken)")
                    print()
                }
            }
            self.classes = fetchedClasses

            DispatchQueue.main.async {
                self.classesCollectionView.reloadData()
            }
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return classes.count
        }

    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClassCell", for: indexPath)

            // Customize the cell
            cell.contentView.subviews.forEach { $0.removeFromSuperview() } // Clear previous content
            let label = UILabel(frame: cell.contentView.bounds)
            label.text = classes[indexPath.item].id
            label.textAlignment = .center
            cell.contentView.addSubview(label)

            cell.contentView.backgroundColor = .lightGray
            cell.layer.cornerRadius = 8

            return cell
        }

        // MARK: - UICollectionViewDelegate

//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let selectedClass = classes[indexPath.item]
//        print("Selected class: \(selectedClass.id)") // Debugging
//
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let detailVC = storyboard.instantiateViewController(withIdentifier: "SelectCourseViewController") as? SelectCourseViewController {
//            detailVC.classData = selectedClass
//            self.navigationController?.pushViewController(detailVC, animated: true)
//        }
//    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSelectCourseSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSelectCourseSegue" {
            if let detailVC = segue.destination as? SelectCourseViewController,
               let indexPath = classesCollectionView.indexPathsForSelectedItems?.first {
                let selectedClass = classes[indexPath.item]
                print("Selected class: \(selectedClass.id)") // Debugging
                // Pass the selected class data to the SelectCourseViewController
                detailVC.modalPresentationStyle = .fullScreen
                detailVC.classData = classes[indexPath.row]
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
    
    func setupCollectionView() {
        print("Setting up Collection View") // Debugging

        classesCollectionView.delegate = self
        classesCollectionView.dataSource = self

        // Register a UICollectionViewCell if not done in the storyboard
        classesCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ClassCell")
    }
    

    
    
}
