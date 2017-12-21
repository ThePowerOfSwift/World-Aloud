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
    
    // Initializer / Deinitializer
    override init() {
        super.init()
        let notificationPhotoCaptured = Notification.Name(rawValue: CameraCapture.NOTIFY_PHOTO_CAPTURED)
        NotificationCenter.default.addObserver(self, selector: #selector(self.processingDoneTakingPhoto), name: notificationPhotoCaptured, object: nil)
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
    public func liveView(){
        self.currentState = .liveView
        self.camera.startSession()
        
        // configure preview and add it to app view
        let viewLayer = self.viewControllerDelegate?.getViewLayer()
        self.cameraPreview = CameraPreview(session: self.camera.getSession(), container: viewLayer!)
        self.cameraPreview?.addPreview()
    }
    
    public func processing(){
        self.currentState = .processing
        self.camera.snapPhoto()
    }
    
    // Executes after the observer captures the notification comming from CameraCapture
    @IBAction private func processingDoneTakingPhoto(){
        self.cameraPreview.removePreview()
        self.camera.stopSession()
        
        if let image = self.camera.getImage() {
            viewControllerDelegate?.displayImage(image, xPosition: 0, yPosition: 0) // show photo on view.
            self.processingTextDetection()
        }
        else { // something went wrong on image capture. Return to live view.
            self.liveView()
        }
    }
    
    private func processingTextDetection(){
        // Remember you can force unwrap self.camera.image as it's been checked before this call
        // Trigger Vision Request
        print("Vision request would be triggered.")
    }
    
    public func reading(){
        self.currentState = .reading
    }
    
    /// Stops all processing or reading activity and goes back to live view
    public func halt(){
        self.currentState = .halt
    }
}
