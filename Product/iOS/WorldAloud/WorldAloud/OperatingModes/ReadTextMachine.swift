//
//  PrintedTextReader.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//  Implemented as a finite state machine, this class controls all of the workflow in recognizing printed text.

import UIKit

enum ReadTextState {
    case initial
    case liveView
    case takingPhoto
    case isolatingText
    case imageProcessing
    case runningOCR
    case reading
    case cleanup
    case background
}

class ReadTextMachine: NSObject {
    // Attributes
    private var currentState: ReadTextState
    private weak var viewControllerDelegate: ViewControllerDelegate? // variable must be weak
    private let camera = CameraCapture()
    private let speech = SpeechSynthesizer() // needs to be unique in order to control multiple requests (Singleton pattern).
    private var preview: CameraPreview?
    private var textFinder: TextFinder?
    private var textReader: TextReader?
    
    // Initializer / Deinitializer
    override init() {
        self.currentState = .initial
        super.init()
        // Setup event observers
        self.setupObserver(name: CameraCapture.NOTIFY_PHOTO_CAPTURED, selector: #selector(self.doneTakingPhoto))
        self.setupObserver(name: CameraCapture.NOTIFY_SESSION_STOPPED, selector: #selector(self.cameraSessionStopped))
        self.setupObserver(name: CameraCapture.NOTIFY_SESSION_STARTED, selector: #selector(self.cameraSessionStarted))
        self.setupObserver(name: TextFinder.NOTIFY_TEXT_DETECTION_COMPLETE, selector: #selector(self.doneFindingText))
        self.setupObserver(name: TextReader.NOTIFY_OCR_COMPLETE, selector: #selector(self.ocrComplete))
        self.setupObserver(name: SpeechSynthesizer.NOTIFY_DONE_SPEAKING, selector: #selector(self.doneSpeaking))
        self.setupObserver(name: SpeechSynthesizer.NOTIFY_DONE_CANCELING, selector: #selector(self.doneCancelingSpeeches))
    }
    private func setupObserver(name: String, selector: Selector) {
        let notification = Notification.Name(rawValue: name)
        NotificationCenter.default.addObserver(self,
                                               selector: selector,
                                               name: notification,
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
    
    public func handleScreenTap() {
        switch self.currentState {
        case .liveView:
            self.takePhoto()
            break
        case .isolatingText, // states that allow canceling
             .runningOCR,
             .reading:
            self.cleanup()
            break
        default: // nothing to do.
            break
        }
    }
    
    public func initial() {
        // This routine gets executed by the viewDidLoad() from the corresponding ViewController.
        print("Initializing state machine.")
        let viewLayer = self.viewControllerDelegate?.getViewLayer()
        self.preview = CameraPreview(session: self.camera.getSession(), container: viewLayer!)
    }
    
    /// Activates camera view
    public func liveView() {
        print("liveView loading...")
        self.camera.startSession()
        DispatchQueue.main.async {
            self.preview?.addPreview()
        }
        print("liveView loaded.")
    }
    
    @IBAction private func cameraSessionStarted(){
        // Application isn't in liveView mode until session has successfully started.
        self.currentState = .liveView
        self.speech.utter("Camera view. Tap to start.")
    }
    
    private func takePhoto() {
        if self.currentState == .liveView {
            print("processing state triggered.")
            self.currentState = .takingPhoto
            speech.utter("Processing.")
            self.camera.snapPhoto()
        }
    }
    
    // Executes after the observer captures the notification comming from CameraCapture
    @IBAction private func doneTakingPhoto() {
        print("Notification received. Photo available for processing.")
        DispatchQueue.main.async {
            self.preview?.removePreview()
        }
        self.camera.stopSession()
    }
    
    @IBAction private func cameraSessionStopped() {
        print("Notification received. AVCapture session stopped.")
        if let image = self.camera.getImage() {
//            viewControllerDelegate?.displayImage(image, xPosition: 0, yPosition: 20) // show photo on view.
            self.currentState = .isolatingText
            self.textFinder = TextFinder(inputImage: image)
            self.textFinder?.findText()
            // notification triggers doneFindingText when done.
        }
        else { // something went wrong on image capture.
            self.cleanup()
        }
    }
    
    @IBAction private func doneFindingText() {
        print("Notification received. Vision processing complete.")
        if (self.currentState == .isolatingText) {
            if let textFinder = self.textFinder {
                let textBoxes = textFinder.getTextBoxes()
                if textBoxes.count <= 0 {
                    self.cleanup(callingState: self.currentState)
                }
                else {
                    self.imageAssembly()
                }
            } else { self.cleanup()}
        }
    }
    
    private func imageAssembly() {
        print("Image assembly triggered.")
        if (self.currentState == .isolatingText) {
            self.currentState = .imageProcessing
            if let textFinder = self.textFinder {
                let image = textFinder.getInputImage()
                
                // Fix orientation and origin of the generated image
                if let imageReoriented = ImageProcessor.fixOrientation(image){
                    
                    // Crop and generate single image
                    //let textBoxes = textFinder.getTextBoxes() // remember these are normalized text boxes
                    UIGraphicsBeginImageContext(imageReoriented.extent.size)
                    UIImage(ciImage: imageReoriented).draw(at: CGPoint(x: 0, y: 0))
                    //        for box in textBoxes {
                    //            let boxAbsolute = ImageProcessor.getAbsoluteRectangleFromNormalized(image: imageFixedTranslation, normalRectangle: box)
                    //            guard let imageStringOfText = ImageProcessor.cropImage(imageFixedTranslation, cropRectangle: boxAbsolute) else {
                    //                print("Error on image crop")
                    //                self.restartLoop()
                    //                return
                    //            }
                    //            UIImage(ciImage: imageStringOfText).draw(at:
                    //                CGPoint(x: boxAbsolute.origin.x,
                    //                        y: imageFixedTranslation.extent.height - boxAbsolute.size.height - boxAbsolute.origin.y))
                    //        }
                    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    print("About to trigger OCR")
                    viewControllerDelegate?.displayImage(finalImage!, xPosition: 0, yPosition: 20)
                    self.textReader = TextReader()
                    self.currentState = .runningOCR
                    self.textReader?.runOCR(image: finalImage!)
                } else {self.cleanup()}
            } else {self.cleanup()}
        }
    }
    
    @IBAction private func ocrComplete() {
        print("Notification received from TextReader. OCR Complete.")
        if self.currentState == .runningOCR {
            if let textReader = self.textReader {
                if let identifiedText = textReader.getRecognizedText() {
                    if !identifiedText.isEmpty {
                        print(identifiedText)
                        self.reading(identifiedText)
                    } else {self.cleanup()}
                } else {self.cleanup()}
            } else {self.cleanup()}
        }
    }
    
    private func reading(_ text: String) {
        print("Triggering read state.")
        self.currentState = .reading
        self.speech.utter(text)
    }
    
    @IBAction private func doneSpeaking() {
        print("Done speaking something")
        if self.currentState == .reading { // remember the Synthesizer broadcasts its message even when it's done speaking a program status
            self.cleanup()
        }
        if self.currentState == .cleanup { // No text found. Go back to liveView
            self.liveView()
        }
    }
    
    /// Stops all processing or reading activity
    public func background() {
        print("Background state called.")
        self.currentState = .background
        self.cleanup(callingState: self.currentState)
    }
    
    private func cleanup() {
        print("Cleanup in progress...")
        self.currentState = .cleanup

        self.textFinder = nil
        if let reader = self.textReader {
            reader.reset()
        }
        
        // remove all subviews previously added
        DispatchQueue.main.async {
            let view = self.viewControllerDelegate?.getView()
            for item in view!.subviews {
                item.removeFromSuperview()
            }
        }
        
        if (self.speech.getSpeech().isSpeaking) {
            self.speech.reset()
        } else {
            self.liveView()
        }
        print("Cleanup execution request completed.")
    }
    
    private func cleanup(callingState: ReadTextState) {
        switch callingState {
        case .background:
            self.currentState = .initial
            break
        case .cleanup:
            self.liveView()
            break
        case .isolatingText:
            // the Vision Framework couldn't find any text.
            print("No text found.")
            self.cleanup()
            self.speech.utter("No text found.")
        default:
            print("Unexpected call. Redirecting to parameterless cleanup().")
            self.cleanup()
            break
        }
    }
    
    @IBAction private func doneCancelingSpeeches(){
        self.cleanup(callingState: self.currentState) // expecting only the cleanup routine causes a speech cancelation.
    }
}
