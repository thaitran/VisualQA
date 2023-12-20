//
//  Recorder.swift
//  Visual Q&A
//
//  Created by Thai Tran on 6/25/23.
//

import Foundation
import AVFoundation

class Recorder: ObservableObject {
    var audioRecorder: AVAudioRecorder!
    
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session")
        }
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioUrl = documentPath.appendingPathComponent("audio.wav")
        
        // Settings to record a WAV file
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioUrl, settings: settings)
            audioRecorder.record()
        } catch {
            print("Could not start recording")
        }
    }
    
    func stopRecording(onComplete: @escaping (String) -> Void) {
        audioRecorder.stop()
        audioRecorder = nil
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioUrl = documentPath.appendingPathComponent("audio.wav")
        
        asrApi(audioUrl: audioUrl, onComplete: onComplete)
    }
}
