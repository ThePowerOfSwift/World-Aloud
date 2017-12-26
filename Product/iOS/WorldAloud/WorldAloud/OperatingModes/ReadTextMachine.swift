//
//  PrintedTextReader.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//  Implemented as a finite state machine, this class controls all of the workflow in recognizing printed text.

import UIKit

enum ReadTextState {
    case initial, liveView, processing, reading, halt, cleanup
}

class ReadTextMachine: NSObject {
    // Attributes
    private var currentState = ReadTextState.initial
    private var camera = CameraCapture()
    private weak var viewControllerDelegate: ViewControllerDelegate? // variable must be weak
    private var cameraPreview: CameraPreview!
    private var speech = SpeechSynthesizer() // needs to be unique in order to control multiple requests (Singleton pattern).
    private var textFinder: TextFinder! // need asynchronous access to it, so I will save it in this scope.
    private var textReader: TextReader!
    
    // internal usage variables (just so we don't have to keep using classes getters all the time as it's more time consuming)
    
    // Initializer / Deinitializer
    override init() {
        super.init()
        
        // Setup event observers
        let notification1 = Notification.Name(rawValue: CameraCapture.NOTIFY_PHOTO_CAPTURED)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.doneTakingPhoto),
                                               name: notification1,
                                               object: nil)
        let notification2 = Notification.Name(rawValue: CameraCapture.NOTIFY_SESSION_STOPPED)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.cameraSessionStopped),
                                               name: notification2,
                                               object: nil)
        let notification3 = Notification.Name(rawValue: TextFinder.NOTIFY_TEXT_DETECTION_COMPLETE)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.doneFindingText),
                                               name: notification3,
                                               object: nil)
        let notification4 = Notification.Name(rawValue: TextReader.NOTIFY_OCR_COMPLETE)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.ocrComplete),
                                               name: notification4,
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
    @IBAction private func doneTakingPhoto() {
        speech.utter("Processing.")
        self.cameraPreview.removePreview()
        self.camera.stopSession()
    }
    
    @IBAction private func cameraSessionStopped() {
        if let image = self.camera.getImage() {
            viewControllerDelegate?.displayImage(image, xPosition: 0, yPosition: 0) // show photo on view.
            
            // trigger vision request
            textFinder = TextFinder(inputImage: self.camera.getImage()!)
            textFinder.findText()
            // notification triggers doneFindingText when done.
        }
        else { // something went wrong on image capture. Return to live view.
            self.cleanup()
            self.liveView()
        }
    }
    
    @IBAction private func doneFindingText() {
        let textBoxes = self.textFinder.getTextBoxes()
        
        if textBoxes.count <= 0 {
            self.cleanup()
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
            self.imageAssembly()
        }
    }
    
    private func imageAssembly() {
        let image = self.textFinder.getInputImage()
        
        // Fix orientation and origin of the generated image
        guard let imageFixedRotation = self.fixRotation(image) else {
            print("Error applying rotation.")
            return
        }
        guard let imageFixedTranslation = ImageProcessor.translateImage(imageFixedRotation,
                                                                        horizontalTranslation: -imageFixedRotation.extent.origin.x,
                                                                        verticalTranslation: -imageFixedRotation.extent.origin.y)
            else {
                print("Error during translation.")
                return
        }
        
        // Crop and generate single image
        let textBoxes = self.textFinder.getTextBoxes() // remember these are normalized text boxes
        UIGraphicsBeginImageContext(imageFixedTranslation.extent.size)
        for box in textBoxes {
            let boxAbsolute = ImageProcessor.getAbsoluteRectangleFromNormalized(image: imageFixedTranslation, normalRectangle: box)
            guard let imageStringOfText = ImageProcessor.cropImage(imageFixedTranslation, cropRectangle: boxAbsolute) else {
                print("Error on image crop")
                return
            }
            UIImage(ciImage: imageStringOfText).draw(at:
                CGPoint(x: boxAbsolute.origin.x,
                        y: imageFixedTranslation.extent.height - boxAbsolute.size.height - boxAbsolute.origin.y))
        }
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        print("About to trigger OCR")
        self.cleanup()
        viewControllerDelegate?.displayImage(finalImage!, xPosition: 0, yPosition: 0)
        self.textReader = TextReader()
        self.textReader.runOCR(image: finalImage!)
    }
    
    @IBAction private func ocrComplete() {
        print("Notification received from TextReader.")
        guard let textReader = self.textReader else {
            print("Error retrieving OCR data.")
            return
        }
        if let identifiedText = textReader.getRecognizedText() {
            print(identifiedText)
            // trigger Speech Synthesizer.
        }
    }
    
    private func fixRotation(_ image: UIImage) -> CIImage? {
        // Required rotation angles were determined experimentally.
        guard let ciImage = CIImage(image: image) else {return nil}
        let orientation = image.imageOrientation.rawValue
        if orientation == 0 { return ciImage }
        let validOrientations: Set<Int> = [1,2,3]
        if !validOrientations.contains(orientation) { return nil }
        let rotationAngles: [Int : CGFloat] = [3 : -CGFloat(Double.pi/2),
                                               2 : CGFloat(Double.pi/2),
                                               1 : CGFloat(Double.pi)]
        return ImageProcessor.rotateImage(ciImage, angle: rotationAngles[orientation]!)
    }
    
    private func reading() {
        self.currentState = .reading
    }
    
    /// Stops all processing or reading activity and goes back to live view
    public func halt() {
        self.currentState = .halt
    }
    
    public func cleanup() {
        self.currentState = .cleanup
        self.speech.reset()
        if let textFinder = self.textFinder {
            textFinder.reset()
        }
        
        // remove all subviews previously added
        let view = viewControllerDelegate?.getView()
        for item in view!.subviews {
            item.removeFromSuperview()
        }
    }
}
