//
//  CameraPreview.swift
//  WorldAloud
//
//  Created by Andre Guerra on 19/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import AVFoundation

/// Provides a preview layer to whatever view calls it.
class CameraPreview: NSObject {
    private var session: AVCaptureSession // session on top of which the preview will run
    private var container: CALayer // the destination container that will hold the preview
    private var previewLayer: AVCaptureVideoPreviewLayer
    
    init(session: AVCaptureSession, container: CALayer) {
        self.session = session
        self.container = container
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect // // Preserve aspect ratio; fit within layer bounds;
        self.previewLayer.frame = container.bounds
        self.previewLayer.contentsGravity = kCAGravityResizeAspectFill
        super.init()
    }
    
    public func addPreview(){
        self.container.insertSublayer(self.previewLayer, at: 0)
    }
    
    public func removePreview(){
        self.previewLayer.removeFromSuperlayer()
    }
}
