//
//  SpeechSynthesizer.swift
//  WorldAloud
//
//  Created by Andre Guerra on 18/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import AVFoundation

// Utters text strings available on its queue upon execution
class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    // ATTRIBUTES
    private var queue = [String]() // chosen a queue in case new requests come in the middle of an uttering.
    private var voice: AVSpeechSynthesisVoice!
    private let speech = AVSpeechSynthesizer()
    public static let NOTIFY_DONE_SPEAKING = "agu3rra.worldAloud.done.speaking"
    public static let NOTIFY_DONE_CANCELING = "agu3rra.worldAloud.done.canceling"
    
    // INITIALIZER
    override init() {
        super.init()
        self.speech.delegate = self
        
        // Setting up default voice
        for availableVoice in AVSpeechSynthesisVoice.speechVoices() {
            if ((availableVoice.language == AVSpeechSynthesisVoice.currentLanguageCode()) &&
                (availableVoice.quality == AVSpeechSynthesisVoiceQuality.enhanced)) {
                self.voice = availableVoice
                print("\(availableVoice.name) selected as voice for uttering speeches. Quality: \(availableVoice.quality.rawValue)")
            }
        }
        if self.voice == nil { // in case no enhanced voice has been found.
            self.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
    }
    
    // GETTERS AND SETTERS
    public func getSpeech() -> AVSpeechSynthesizer {
        return self.speech
    }
    
    // METHODS
    public func utter() { // my 1st real world overloading in Swift :)
        if !self.speech.isSpeaking {
            if self.queue.count > 0 {
                let speechString = self.queue.removeFirst()
                let utterance = AVSpeechUtterance(string: speechString)
                guard let voice = self.voice else {fatalError("Error loading voice")}
                utterance.voice = voice
                self.speech.speak(utterance)
            } else {print("Execution call on empty speech queue.");return}
        } // if there was an utterance in progress, text is added to queue and executed when utterance finishes.
        else {
            print("Speech in progress. Adding new request to queue.")
        }
    }
    public func utter(_ text: String!) {
        print("Receiving new string to utter...")
        self.queue.append(text)
        self.utter()
    }

    /// stops any utterances in progress and empties queue
    func reset(){
        print("Reseting speech...")
        if speech.isSpeaking {
            speech.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
        self.queue = [String]() // reset queue
        print("Speech reset complete.")
    }
    
    // DELEGATE METHODS
    internal func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if self.queue.count > 0 {
            self.utter()
        }
        broadcastNotification(name: SpeechSynthesizer.NOTIFY_DONE_SPEAKING)
    }
    
    internal func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Cancelled speeches in progress.")
        broadcastNotification(name: SpeechSynthesizer.NOTIFY_DONE_CANCELING)
    }
}
