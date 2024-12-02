//
//  ViewController.swift
//  StudyArena
//
//  Created by Isha Vasil on 11/6/24.
//

import UIKit
import FirebaseFirestore
import FirebaseDatabase

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {
    
    
    
    @IBOutlet weak var classesCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var ref: DatabaseReference!
    var classes: [ClassData] = [] // Array to hold fetched class data
    var filteredClasses: [ClassData] = []
    
    let ai = OpenAIService()
    
    
    var assistantID:String = "";
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        
        setupCollectionView()
        fetchClassesData()
        setupSearchBar()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.addClassData(classID: "cse131", assistant: "asst_R98EZmBJAJITwPBicjQhTaEx", averageScore: 14, highScore: 15, lowScore: 13, quizzesTaken: 10)
        }
        
        ai.sendMessageToAssistant(assistantId: assistantID) { response in
            print(response ?? "no message recieved");
        }
        
    }
    
    func setupCollectionView() {
        print("Setting up Collection View") // Debugging

        classesCollectionView.delegate = self
        classesCollectionView.dataSource = self

        // Register a UICollectionViewCell if not done in the storyboard
        classesCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ClassCell")
    }
    
    func setupSearchBar() {
            searchBar.delegate = self
    }
    
    @IBAction func addNewCourseTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addCourseVC = storyboard.instantiateViewController(withIdentifier: "AddCourseViewController") as? AddCourseViewController {
            self.navigationController?.pushViewController(addCourseVC, animated: true)
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
            self.filteredClasses = fetchedClasses // Initially show all classes
            DispatchQueue.main.async {
                self.classesCollectionView.reloadData()
            }
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return filteredClasses.count
        }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClassCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() } // Clear previous content

        // Configure the label
        let label = UILabel(frame: cell.contentView.bounds)
        label.text = filteredClasses[indexPath.item].id // Display course name
        label.textAlignment = .center
        label.numberOfLines = 0 // Allow multiline text
        label.lineBreakMode = .byWordWrapping

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
        let selectedClass = filteredClasses[indexPath.item] // Use filteredClasses for search compatibility
        print("didSelectItemAt: \(selectedClass.id)") // Debugging
        performSegue(withIdentifier: "ShowSelectCourseSegue", sender: selectedClass)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSelectCourseSegue" {
            if let detailVC = segue.destination as? SelectCourseViewController,
               let selectedClass = sender as? ClassData { // Retrieve the passed ClassData object
                print("Selected class: \(selectedClass.id)") // Debugging
                // Pass the selected class data to the SelectCourseViewController
                detailVC.modalPresentationStyle = .fullScreen
                detailVC.classData = selectedClass
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Set a fixed size for all cells
        let width = collectionView.bounds.width - 20 // Add padding if needed
        let height: CGFloat = 100 // Set a uniform height for all cells
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10 // Spacing between rows
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0 // Spacing between items in the same row
    }

    

    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            // Show all classes if search text is empty
            filteredClasses = classes
        } else {
            // Filter classes based on the search query
            filteredClasses = classes.filter { $0.id.lowercased().contains(searchText.lowercased()) }
        }
        classesCollectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // Dismiss the keyboard when search is pressed
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
