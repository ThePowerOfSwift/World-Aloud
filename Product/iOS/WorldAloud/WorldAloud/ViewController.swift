//
//  ViewController.swift
//  WorldAloud
//
//  Created by Andre Guerra on 17/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit

protocol ViewControllerDelegate:class {
    func getView() -> UIView
    func getViewLayer() -> CALayer
    func displayImage(_ image: UIImage, xPosition: CGFloat, yPosition: CGFloat)
}

class ViewController: UIViewController, UIGestureRecognizerDelegate, ViewControllerDelegate {
    var operatingMode: Any? // This can become either a TextReader or a CashRecognizer or an ObjectClassifier
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black // I think this looks better.
        configureGestures()
        operatingMode = ReadTextMachine() // initilize in this mode. Following versions will allow change in op mode thru swipe.
        let mode = operatingMode as! ReadTextMachine
        mode.setViewControllerDelegate(viewController: self)
        mode.initial()
        print("ViewController loaded.")
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
            if operatingMode is ReadTextMachine{
                let operatingMode = operatingMode as! ReadTextMachine
                operatingMode.handleScreenTap()
            }
        }
    }
    
    
    // ViewControllerDelegate protocol functions
    /// Returns this ViewController's view object (as reference) to any class or object that conforms to ViewControllerDelegate
    public func getView() -> UIView {
        return self.view
    }
    
    public func getViewLayer() -> CALayer {
        return self.view.layer
    }
    
    public func displayImage(_ image: UIImage, xPosition: CGFloat, yPosition: CGFloat){
        DispatchQueue.main.async {
            let conversionRatio = self.view.frame.width / image.size.width
            let scaledHeigth = conversionRatio * image.size.height
            let imageView = UIImageView(frame: CGRect(x: xPosition, y: yPosition, width: self.view.frame.width, height: scaledHeigth))
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            self.view.addSubview(imageView)
        }
    }
    
}

