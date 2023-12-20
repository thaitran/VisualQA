//
//  API.swift
//  Visual Q&A
//
//  Created by Thai Tran on 6/25/23.
//

import Foundation
import SwiftUI

let server = "http://10.0.0.36:4000"

struct MultimodalJsonResponse: Codable {
    let response: String?
    let error: String?
}

struct AsrJsonResponse: Codable {
    let transcription: String?
    let error: String?
}

func multimodalApi(image: UIImage, prompt: String, onComplete: @escaping (String) -> Void) {
    print("multimodalApi Prompt: \(prompt)")
    
    let url = URL(string: server + "/multimodal")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
    
    let boundary = UUID().uuidString
    let contentType = "multipart/form-data; boundary=\(boundary)"
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")

    var data = Data()
    
    // Start of the multipart/form-data body
    
    // Insert Prompt
    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
    data.append("\(prompt)".data(using: .utf8)!)
    
    // Insert Image
    data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"file\"; filename=\"yourfile.txt\"\r\n".data(using: .utf8)!)
    data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    
    data.append(imageData)
    data.append("\r\n".data(using: .utf8)!)
    
    // End of the multipart/form-data body
    data.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = data
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // handle response from server
        if let data = data {
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(MultimodalJsonResponse.self, from: data)
                if let response = decodedResponse.response {
                    print("multimodalApi Response: \(response)")
                    onComplete(response)
                } else if let errorMessage = decodedResponse.error {
                    print("multimodalApi Error: \(errorMessage)")
                }
            } catch {
                print("multimodalApi JSON decoding error: \(error)")
            }
        }
    }
    task.resume()
}

func asrApi(audioUrl: URL, onComplete: @escaping (String) -> Void) {
    let url = URL(string: server + "/asr")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var data = Data()
    
    let audioData = try? Data(contentsOf: audioUrl)

    // Start of the multipart/form-data body
    data.append("--\(boundary)\r\n".data(using: .utf8)!)
    data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
    data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
    
    data.append(audioData!)
    data.append("\r\n".data(using: .utf8)!)
    
    // End of the multipart/form-data body
    data.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = data
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // handle response from server
        if let data = data {
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(AsrJsonResponse.self, from: data)
                if let transcription = decodedResponse.transcription {
                    print("asrApi Transcription: \(transcription)")
                    onComplete(transcription)
                } else if let errorMessage = decodedResponse.error {
                    print("asrApi Error: \(errorMessage)")
                }
            } catch {
                print("asrApi JSON Decoding error: \(error)")
            }
        }
    }
    task.resume()
}

func ttsApi(message: String, onComplete: @escaping (Data) -> Void) {
    let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    let url = URL(string: server + "/tts/" + encodedMessage!)
    
    if let url = url {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // handle response from server
            if let data = data {
                print("ttsApi: \(message)")
                onComplete(data)
            }
        }
        task.resume()
    }
    
    
}
