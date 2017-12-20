//
//  ViewController.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit

protocol ViewControllerDelegate:class {
    func getViewLayer() -> CALayer
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, ViewControllerDelegate {
    var operatingMode: Any? // This can become either a TextReader or a CashRecognizer or an ObjectClassifier
    
    /// Returns this ViewController's view object (as reference) to any class or object that conforms to ViewControllerDelegate
    public func getViewLayer() -> CALayer {
        return self.view.layer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black // I think this looks better.
        configureGestures()
        operatingMode = TextReader() // initilize in this mode. Following versions will allow change in op mode thru swipe.
        let mode = operatingMode as! TextReader
        mode.setViewControllerDelegate(viewController: self)
    }
    
    private func configureGestures(){
        // Configures and adds a tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        tap.delegate = self
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1 // single finger tap
        self.view.addGestureRecognizer(tap)
    }

    // Gesture handlers
    @IBAction func handleTap(sender: UITapGestureRecognizer){
        if (sender.state == .ended) {
            guard let operatingMode = self.operatingMode else {fatalError("Unable to retrieve operating mode.")}
            
            // Gesture responses to TextReader mode.
            if operatingMode is TextReader{
                let operatingMode = operatingMode as! TextReader
                let currentState = operatingMode.getCurrentState()
                switch currentState {
                case TextReaderState.liveView:
                    operatingMode.processing()
                    break
                case TextReaderState.processing, .reading:
                    operatingMode.halt()
                    break
                default: // nothing to do.
                    break
                }
            }
        }
    }
    
    
    
}

