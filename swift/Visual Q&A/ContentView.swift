//
//  ContentView.swift
//  Visual Q&A
//
//  Created by Thai Tran on 6/25/23.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var modelData: ModelData
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    @State private var audioPlayer: AVAudioPlayer?
    
    @StateObject private var recorder = Recorder()
    @State private var isRecording = false
    
    var body: some View {
        VStack {
            if let inputImage = inputImage {
                Image(uiImage: inputImage)
                    .resizable()
                    .scaledToFit()
            }
            
            ScrollView {
                Text(modelData.chatlog)
                    .padding()
            }
            .border(modelData.chatlog == "" ? Color.clear : Color.black, width: 0.5)
            
            HStack {
                Button(action: {
                    self.showingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title)
                        Text("Take Photo")
                    }
                }
                .padding()
                Button(action: {
                    /*
                    isRecording.toggle()
                    if isRecording {
                        recorder.startRecording()
                    } else {
                        recorder.stopRecording(onComplete: questionTranscribed)
                    }
                     */
                }) {
                    VStack {
                        Image(systemName: "mic")
                            .font(.title)
                        Text("Ask Question")
                        //Text(isRecording ? "Stop Recording" : "Ask Question")
                    }
                }
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    if pressing {
                        print("Button pressed")
                        recorder.startRecording()
                    } else {
                        print("Button released")
                        recorder.stopRecording(onComplete: questionTranscribed)
                    }
                }) { }
                .disabled(modelData.chatlog.isEmpty)
                .padding()
            }
        }
        .padding()
        .sheet(isPresented: $showingImagePicker, onDismiss: loadNewImage) {
            ImagePicker(image: self.$inputImage)
        }
    }
    
    func loadNewImage() {
        if let inputImage = inputImage {
            DispatchQueue.main.async {
                modelData.reset()
            }
            multimodalApi(image: inputImage, prompt: "", onComplete: getImageDescription)
        }
    }
    
    func getImageDescription(response: String) {
        DispatchQueue.main.async {
            modelData.addImageDescription(description: response)
            ttsApi(message: response, onComplete: playAudio)
        }
    }
    
    func playAudio(data: Data) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("Audio session category is now \(session.category)")
        } catch {
            print("Failed to set audio session category.")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            if let audioPlayer = audioPlayer {
                print("playAudio: \(data.count)")
                audioPlayer.volume = 1.0
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
        } catch let error {
            print("AVAudioPlayer init failed: \(error.localizedDescription)")
        }
    }
    
    func questionTranscribed(transcription: String) {
        if let inputImage = inputImage {
            DispatchQueue.main.async {
                modelData.addQuestion(question: transcription)
                multimodalApi(image: inputImage, prompt: modelData.chatlog, onComplete: getAnswer)
            }
        }
    }
    
    func getAnswer(response: String) {
        if response == "" {
            DispatchQueue.main.async {
                modelData.addAnswer(answer: "<Not Answered>")
            }
        } else {
            DispatchQueue.main.async {
                modelData.addAnswer(answer: response)
                ttsApi(message: response, onComplete: playAudio)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ModelData())
    }
}
