//
//  PrintedTextReader.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//  The Text Reader class 

import UIKit

enum TextReaderState {
    case initial, liveView, processing, reading, halt
}

class TextReader: NSObject {
    // Attributes
    private var currentState = TextReaderState.initial
    private var camera = CameraCapture()
    private weak var viewControllerDelegate: ViewControllerDelegate? // variable must be weak 
    
    // Getters and Setters
    public func getCurrentState() -> TextReaderState {
        return self.currentState
    }
    public func setViewControllerDelegate(viewController: ViewController) {
        // call this from the ViewController so it can be accessed from here.
        self.viewControllerDelegate = viewController
    }
    
    // Operations
    /// Activates camera view 
    public func liveView(){
        self.currentState = .liveView
        self.camera.startSession()
        
        // Add preview to main view
        let viewLayer = self.viewControllerDelegate?.getViewLayer()
        let cameraPreview = CameraPreview(session: self.camera.getSession())
        let preview = cameraPreview.configurePreview(container: viewLayer!)
        cameraPreview.addPreview(container: viewLayer!, previewLayer: preview)
    }
    
    public func processing(){
        self.currentState = .processing
        self.camera.snapPhoto()
    }
    
    public func reading(){
        self.currentState = .reading
    }
    
    /// Stops all processing or reading activity and goes back to live view
    public func halt(){
        self.currentState = .halt
    }
}
