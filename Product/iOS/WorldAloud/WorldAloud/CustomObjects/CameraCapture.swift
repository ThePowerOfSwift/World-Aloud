//
//  Camera.swift
//  WorldAloud
//
//  Created by Andre Guerra on 18/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import AVFoundation

/// Sets up the camera and captures images from it.
class CameraCapture: NSObject, AVCapturePhotoCaptureDelegate {
    // Attributes
    private var authorization = AVCaptureDevice.authorizationStatus(for: AVMediaType.video) // authorization status of the camera device
    private var session = AVCaptureSession()
    private var output = AVCapturePhotoOutput()
    private var image: UIImage?
    private var deviceOrientationOnCapture: UIDeviceOrientation!
    
    static let NOTIFY_PHOTO_CAPTURED = "guerra.andre.worldAloud.photo.captured"
    
    // Initialization
    override init(){
        super.init()
        self.authorizationCheck()
        self.session = configureCaptureSession()
    }
    
    // Getters and Setters
    public func getSession() -> AVCaptureSession {
        return self.session
    }
    public func getImage() -> UIImage? {
        return self.image
    }
    
    // Methods
    /// Checks for current access authorization on the device's camera and asks for it if it is not yet determined.
    private func authorizationCheck(){
        if self.authorization == .notDetermined {
            // Utter "Camera access required. Please grant it."
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {
                (granted: Bool) -> Void in
                if (granted) {print("Granted.")} // replace this line for voice over.
                else {print("Denied.")} // replace this line for voice over.
                self.authorization = AVCaptureDevice.authorizationStatus(for: AVMediaType.video) // update internal variable
            })
        } // unable to add further action as if user denies access on first attempt, it must be granted thru iOS's setup menu.
    }
    
    /// Retrieves a camera device to be used in the application
    private func defaultDevice() -> AVCaptureDevice{
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) { //
            return device // use dual rear cameras when available
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device // use default back facing camera
        } else{
            fatalError("No back camera available on this device.")
        }
    }
    
    private func configureCaptureSession() -> AVCaptureSession{
        // get video input from default camera
        let videoCaptureDevice = self.defaultDevice()
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {fatalError("Unable to obtain video input from default camera.")}
        // create and configure photo output
        let capturePhotoOutput = AVCapturePhotoOutput()
        capturePhotoOutput.isHighResolutionCaptureEnabled = true
        capturePhotoOutput.isLivePhotoCaptureEnabled = false
        // check that you can add input and output to session
        let session = AVCaptureSession()
        guard session.canAddInput(videoInput) else {fatalError("Unable to add input to capture session.")}
        guard session.canAddOutput(capturePhotoOutput) else {fatalError("Unable to add output to capture session")}
        // configure session
        session.beginConfiguration()
        session.sessionPreset = .photo
        session.addInput(videoInput)
        session.addOutput(capturePhotoOutput)
        session.commitConfiguration()
        // save the output to call the snap photo routine later
        self.output = capturePhotoOutput
        return session
    }
    
    public func startSession() {
        if self.session.isRunning {
            return
        }
        self.session.startRunning()
        print("Live capture started.")
    }
    
    public func stopSession() {
        if !self.session.isRunning {
            print("already stopped")
            return
        }
        self.session.stopRunning()
        print("Live capture stopped.")
    }
    
    public func snapPhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        self.output.capturePhoto(with: photoSettings, delegate: self) // Trigger image capture. It needs a runing session to work.
    }
    
    internal func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        self.deviceOrientationOnCapture = UIDevice.current.orientation
    }
    
    internal func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        var fail = true
        if let imageData = photo.fileDataRepresentation() { // successfully generated image.
            if let image = UIImage(data: imageData){ // successfully generated an UIImage from flat data file.
                if let orientation = self.deviceOrientationOnCapture{
                    if let image = image.cgImage { // convert to CGImage prior to re-converting back to UIImage in order to pass orientation
                        self.image = UIImage(cgImage: image, scale: 1.0, orientation: orientation.getUIImageOrientationFromDevice())
                        fail = false
                    }
                }
            }
        }
        if (fail) { // I needed this because guard let on the above statements required too much else statements with the same things.
            self.image = nil
        }
        
        // Notify that the instance is done processing photo.
        let name = Notification.Name(rawValue: CameraCapture.NOTIFY_PHOTO_CAPTURED)
        NotificationCenter.default.post(name: name, object: self)
    }
    
    
}
