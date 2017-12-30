//
//  TextFinder.swift
//  WorldAloud
//
//  Created by Andre Guerra on 20/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import Vision

// Uses Apple's Vision Framework to detect text regions. This is done to minimize the work required by the OCREngine.
// Detecting text is one thing. Converting Text is another. This one if the former.
class TextFinder: NSObject{
    // ATTRIBUTES
    private var inputImage: UIImage
    private var textBoxes = [CGRect]()
    public static let NOTIFY_TEXT_DETECTION_COMPLETE = "agu3rra.worldAloud.text.detection.complete"
    
    // INITIALIZER
    init(inputImage: UIImage) {
        self.inputImage = inputImage
        super.init()
    }
    
    // GETTERS AND SETTERS
    public func getInputImage() -> UIImage {
        return self.inputImage
    }
    
    public func getTextBoxes() -> [CGRect] {
        return self.textBoxes
    }
    
    // METHODS
    public func findText() {
        // Generate CGImage and Orientation so we can pass that info to the Vision Request.
        guard let image = self.inputImage.cgImage else { // generate CGImage from the UIImage
            print("Unable to convert image to CGImage on findText");
            return
        }
        let orientation = self.inputImage.imageOrientation.getCGOrientationFromUIImage()
        
        // Vision Framework request setup
        let textDetectionRequest = VNDetectTextRectanglesRequest(completionHandler: self.findTextBoxes)
        let textDetectionHandler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        DispatchQueue.global(qos: .background).async {
            do {
                try textDetectionHandler.perform([textDetectionRequest])
            } catch {
                print(error)
            }
        }
        
    }
    
    private func findTextBoxes(request: VNRequest, error: Error?){
        if let error = error {
            print("Detection failed. Error: \(error)")
            return
        }
        request.results?.forEach({(result) in
            guard let observation = result as? VNTextObservation else {print("No observation detected.");return}
            let boundingBox = observation.boundingBox
            self.textBoxes.append(boundingBox)
        })
        broadcastNotification(name: TextFinder.NOTIFY_TEXT_DETECTION_COMPLETE)
    }
    
    public func reset() {
        self.textBoxes = [CGRect]()
    }
    
}
