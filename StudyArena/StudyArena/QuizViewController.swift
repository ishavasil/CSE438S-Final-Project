import UIKit

class QuizViewController: UIViewController {

    @IBOutlet weak var questionNumberLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startQuizButton: UIButton!

    let dummyQuestions: [QuizQuestion] = [
        QuizQuestion(
            question: "Which of the following is a low-overhead option for communicating with 'the cloud'?",
            option1: "XML",
            option2: "JSON",
            option3: "CSV",
            option4: "HTML",
            correctOption: "option2"
        ),
        QuizQuestion(
            question: "What does HTTP stand for?",
            option1: "Hypertext Transfer Protocol",
            option2: "Hyperlink Text Processing",
            option3: "Hyper Transfer Process",
            option4: "High-level Text Protocol",
            correctOption: "option1"
        ),
        QuizQuestion(
            question: "Which programming language is used to build iOS apps?",
            option1: "Java",
            option2: "Swift",
            option3: "Python",
            option4: "C++",
            correctOption: "option2"
        )
    ]

    var questions: [QuizQuestion] = []
    var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    var quizTimer: Timer?
    var timeRemaining: Int = 150

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForQuizState(started: false)
        questions = dummyQuestions
    }

    @IBAction func startQuizTapped(_ sender: UIButton) {
        resetQuiz()
        startQuiz()
    }

    func resetQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        timeRemaining = 150
    }

    func startQuiz() {
        questions = dummyQuestions
        updateUIForQuizState(started: true)
        showNextQuestion()
        startTimer()
    }

    func showNextQuestion() {
        if currentQuestionIndex < questions.count {
            let question = questions[currentQuestionIndex]

            // Instantiate QuestionViewController
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let questionVC = storyboard.instantiateViewController(withIdentifier: "QuestionViewController") as? QuestionViewController {
                questionVC.questionData = question
                questionVC.questionNumber = currentQuestionIndex + 1
                questionVC.completionHandler = { [weak self] isCorrect in
                    guard let self = self else { return }

                    if isCorrect {
                        self.correctAnswers += 1
                    }

                    self.currentQuestionIndex += 1

                    if self.currentQuestionIndex < self.questions.count {
                        self.showNextQuestion()
                    } else {
                        self.showQuizEndScreen()
                    }
                }

                // Push the QuestionViewController to create a fast transition
                if let navController = self.navigationController {
                    navController.pushViewController(questionVC, animated: false)
                }
            }
        }
    }


    func showQuizEndScreen() {
        updateUIForQuizState(started: false)
        stopTimer()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let quizEndVC = storyboard.instantiateViewController(withIdentifier: "QuizEndViewController") as? QuizEndViewController {
            quizEndVC.finalScore = correctAnswers
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
