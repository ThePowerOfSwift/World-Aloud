//
//  PrintedTextReader.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//  Implemented as a finite state machine, this class controls all of the workflow in recognizing printed text.

import UIKit

enum ReadTextState {
    case initial, liveView, processing, reading, halt
}

class ReadTextMachine: NSObject {
    // Attributes
    private var currentState = ReadTextState.initial
    private var camera = CameraCapture()
    private weak var viewControllerDelegate: ViewControllerDelegate? // variable must be weak
    private var cameraPreview: CameraPreview!
    private var speech = SpeechSynthesizer() // needs to be unique in order to control multiple requests (Singleton pattern).
    private var textFinder: TextFinder! // need asynchronous access to it, so I will save it in this scope.
    
    // Initializer / Deinitializer
    override init() {
        super.init()
        
        // Setup event observers
        let notification1 = Notification.Name(rawValue: CameraCapture.NOTIFY_PHOTO_CAPTURED)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.processingDoneTakingPhoto),
                                               name: notification1,
                                               object: nil)
        let notification2 = Notification.Name(rawValue: TextFinder.NOTIFY_TEXT_DETECTION_COMPLETE)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.processingDoneFindingText),
                                               name: notification2,
                                               object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self) // cleanup observer once instance no longer exists
    }
    
    // Getters and Setters
    public func getCurrentState() -> ReadTextState {
        return self.currentState
    }
    public func setViewControllerDelegate(viewController: ViewController) {
        // call this from the ViewController so that ViewController can be accessed from here.
        self.viewControllerDelegate = viewController
    }
    
    // Operations
    /// Activates camera view 
    public func liveView() {
        self.currentState = .liveView
        // add a cleanup routine either here or on halt. Decide later.
        
        self.camera.startSession()
        
        // configure preview and add it to app view
        let viewLayer = self.viewControllerDelegate?.getViewLayer()
        self.cameraPreview = CameraPreview(session: self.camera.getSession(), container: viewLayer!)
        self.cameraPreview?.addPreview()
        
        // inform user that app is in live view mode
        speech.utter("Camera view. Tap to start.")
    }
    
    public func processing() {
        self.currentState = .processing
        self.camera.snapPhoto()
    }
    
    // Executes after the observer captures the notification comming from CameraCapture
    @IBAction private func processingDoneTakingPhoto() {
        speech.utter("Processing.")
        self.cameraPreview.removePreview()
        self.camera.stopSession()
        
        if let image = self.camera.getImage() {
            viewControllerDelegate?.displayImage(image, xPosition: 0, yPosition: 0) // show photo on view.
            
            // trigger vision request
            textFinder = TextFinder(inputImage: self.camera.getImage()!)
            textFinder.findText()
            // notification triggers processingDoneFindingText when done.
        }
        else { // something went wrong on image capture. Return to live view.
            self.liveView()
        }
    }
    
    @IBAction private func processingDoneFindingText() {
        DispatchQueue.main.async {
            let textBoxes = self.textFinder.getTextBoxes()
            
            if textBoxes.count <= 0 {
                self.speech.utter("No text found.")
                self.liveView()
            }
            else {
                // Draw red boxes on top of user view.
                let image = self.textFinder.getInputImage()
                // previous process ran on the background, so we need to change back to the main queue in order to update the UI.
                
                let view = self.viewControllerDelegate?.getView()
                let viewFrameWidth = view!.frame.width
                let conversionRatio = viewFrameWidth / image.size.width
                let scaledHeight = conversionRatio * image.size.height
                for box in textBoxes {
                    let x = viewFrameWidth * box.origin.x // + imageView.frame.origin.x
                    let width = viewFrameWidth * box.width
                    let height = scaledHeight * box.height
                    let y = scaledHeight * (1-box.origin.y) - height // + imageView.frame.origin.y
                    let textRectangle = CGRect(x: x, y: y, width: width, height: height)
                    
                    // Draw rectangles on UI for areas of detected text
                    let redBox = UIView()
                    redBox.backgroundColor = .red
                    redBox.alpha = 0.25
                    redBox.frame = textRectangle
                    view!.addSubview(redBox)
                }
                
            }
        }
        
        // Feed image and boxes to a process that returns a single image
    }
    
    private func reading() {
        self.currentState = .reading
    }
    
    /// Stops all processing or reading activity and goes back to live view
    public func halt() {
        self.currentState = .halt
    }
}
