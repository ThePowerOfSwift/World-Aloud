//
//  TextReader.swift
//  WorldAloud
//
//  Created by Andre Guerra on 20/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import TesseractOCR

// Reads text from images.
class TextReader: NSObject, G8TesseractDelegate {
    // ATTRIBUTES
    private var recognizedText: String?
    private var tesseract: G8Tesseract
    public static let NOTIFY_OCR_COMPLETE = "agu3rra.worldAloud.ocr.complete"
    private var cancelOngoingRequest: Bool
    
    // INITIALIZATION
    override init() {
        self.cancelOngoingRequest = false
        self.tesseract = G8Tesseract(language: "eng")
        super.init()
        self.tesseract.delegate = self
        self.tesseract.charWhitelist = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUWXYZ$,.:!@%?"
    }
    
    // GETTERS AND SETTERS
    public func getRecognizedText() -> String? {
        return self.recognizedText
    }
    
    // METHODS
    public func runOCR(image: UIImage) {
        DispatchQueue.global(qos: .background).async {
            self.tesseract.image = image
            self.tesseract.recognize()
            self.recognizedText = self.tesseract.recognizedText
            print("Recognition complete.")
            broadcastNotification(name: TextReader.NOTIFY_OCR_COMPLETE)
        }
    }
    
    public func reset() {
        print("Request to cancel recognition received.")
        self.cancelOngoingRequest = true
        let cancel = self.shouldCancelImageRecognition(for: self.tesseract)
        if cancel {
            print("OCR request cancelled.")
        } else {
            print("Something went wront while canceling OCR request.")
        }
    }
    
    internal func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        if self.cancelOngoingRequest {
            self.cancelOngoingRequest = false
            return true
        } else {
            return false
        }
    }
}
