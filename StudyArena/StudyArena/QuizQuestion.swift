//
//  QuizQuestion.swift
//  StudyArena
//
//  Created by Pranav Palakodety on 12/1/24.
//

import Foundation

struct QuizQuestion: Codable {
    let question: String
    let option1: String
    let option2: String
    let option3: String
    let option4: String
    let correctOption: String
}
