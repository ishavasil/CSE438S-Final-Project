import UIKit

class QuizViewController: UIViewController {

    @IBOutlet weak var questionNumberLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startQuizButton: UIButton!
    var classData: ClassData? 
        
    
    var questions: [QuizQuestion] = []

    var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    var quizTimer: Timer?
    var timeRemaining: Int = 150

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up loading screen
        let loadingView = UIView(frame: self.view.bounds)
        loadingView.backgroundColor = UIColor(white: 0.0, alpha: 0.7) // Semi-transparent background
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = loadingView.center
        activityIndicator.startAnimating()
        loadingView.addSubview(activityIndicator)
        self.view.addSubview(loadingView)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Perform loading tasks
            var thread = "thread_nkXspzjfX8QpMGJOc4EziICx"
            // var thread = classData?.assistant ?? "none"
            let ai = OpenAIService(ThreadID: thread)
            var loadedQuestions = [QuizQuestion]()
            
            for _ in 1...10 {
                loadedQuestions.append(ai.getQuestion())
            }
            
            DispatchQueue.main.async {
                // Update UI on the main thread
                self.questions = loadedQuestions
                loadingView.removeFromSuperview() // Remove the loading view
                // self.updateUIForQuizState(started: false) // Uncomment if needed
                print("in quiz view controller data: ")
                print(self.classData ?? "none")
            }
        }
    }


    @IBAction func startQuizTapped(_ sender: UIButton) {
        print("start Quiz tapped")
        resetQuiz()
        startQuiz()
        
    }

    func resetQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        timeRemaining = 150
    }

    func startQuiz() {
        print("start Quiz triggered")
        updateUIForQuizState(started: true)
        showNextQuestion()
        startTimer()
    }

    func showNextQuestion() {
        if currentQuestionIndex < questions.count {
            let question = questions[currentQuestionIndex]

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let questionVC = storyboard.instantiateViewController(withIdentifier: "QuestionViewController") as? QuestionViewController {
                questionVC.questionData = question
                questionVC.questionNumber = currentQuestionIndex + 1
                questionVC.completionHandler = { [weak self] isCorrect in
                    guard let self = self else { return }

                    if isCorrect {
                        self.correctAnswers += 1
                        print("correct answer")
                    }

                    self.currentQuestionIndex += 1

                    if self.currentQuestionIndex < self.questions.count {
                        self.showNextQuestion()
                    } else {
                        self.showQuizEndScreen()
                    }
                }
                
                self.navigationController!.pushViewController(questionVC, animated: true)
            }
        }
    }


    func showQuizEndScreen() {
        updateUIForQuizState(started: false)
        stopTimer()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let quizEndVC = storyboard.instantiateViewController(withIdentifier: "QuizEndViewController") as? QuizEndViewController {
            quizEndVC.finalScore = correctAnswers
            quizEndVC.classData = self.classData
            
            navigationController?.pushViewController(quizEndVC, animated: true)
        }
    }

    

    
    func startTimer() {
        guard quizTimer == nil else { return }
        timerLabel.isHidden = false
        updateTimerLabel()

        quizTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.timeRemaining -= 1
            self.updateTimerLabel()

            if self.timeRemaining <= 0 {
                timer.invalidate()
                self.quizTimer = nil
                self.showQuizEndScreen()
            }
        }
    }

    func stopTimer() {
        quizTimer?.invalidate()
        quizTimer = nil
    }

    func updateTimerLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    func updateUIForQuizState(started: Bool) {
        questionNumberLabel.isHidden = !started
        startQuizButton.isHidden = started
        timerLabel.isHidden = !started
    }
}
