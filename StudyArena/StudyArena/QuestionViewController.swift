import UIKit

class QuestionViewController: UIViewController {
    
    @IBOutlet weak var questionNumberLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var option1Button: UIButton!
    @IBOutlet weak var option2Button: UIButton!
    @IBOutlet weak var option3Button: UIButton!
    @IBOutlet weak var option4Button: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    var questionData: QuizQuestion?
    var questionNumber: Int = 1
    var completionHandler: ((Bool) -> Void)?
    
    var timer: Timer?
    var timeRemaining: Int = 30
    var hasAnswered: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("questionData");
        
        if let question = questionData {
            questionNumberLabel.text = "Question \(questionNumber)/10"
            questionLabel.text = question.question
            option1Button.setTitle(question.option1, for: .normal)
            option2Button.setTitle(question.option2, for: .normal)
            option3Button.setTitle(question.option3, for: .normal)
            option4Button.setTitle(question.option4, for: .normal)
        }
        
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        updateTimerLabel()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.updateTimerLabel()
            
            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                self.timer = nil
                self.handleTimeout()
            }
        }
    }
    
    func updateTimerLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    func handleTimeout() {
        guard !hasAnswered else { return }
        
        hasAnswered = true
        completionHandler?(false)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func optionSelected(_ sender: UIButton) {
        guard let question = questionData, !hasAnswered else { return }
        
        hasAnswered = true
        option1Button.isEnabled = false
        option2Button.isEnabled = false
        option3Button.isEnabled = false
        option4Button.isEnabled = false
        
        let selectedOption = sender == option1Button ? "option1" :
        sender == option2Button ? "option2" :
        sender == option3Button ? "option3" :
        "option4"
        let isCorrect = (selectedOption == question.correctOption)
        
        // Stop the timer if it's running
        timer?.invalidate()
        timer = nil
        
        // Call the completion handler to pass back the result
        completionHandler?(isCorrect)
        
        // Instead of dismissing, let QuizViewController handle the next question immediately
       
    }
}
