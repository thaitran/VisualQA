//
//  ModelData.swift
//  Visual Q&A
//
//  Created by Thai Tran on 6/25/23.
//

import Foundation

final class ModelData: ObservableObject {
    @Published var chatlog = ""
    
    func reset() {
        chatlog = ""
    }
    
    func addImageDescription(description: String) {
        chatlog = "Context: \(description)\n"
    }
    
    func addQuestion(question: String) {
        chatlog += "Question: \(question)\nAnswer: "
    }
    
    func addAnswer(answer: String) {
        chatlog += "\(answer)\n"
    }
}
