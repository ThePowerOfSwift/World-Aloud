//
//  CameraPreview.swift
//  WorldAloud
//
//  Created by Andre Guerra on 19/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import AVFoundation

/// This class is responsible for providing a preview layer to whatever view calls it.
class CameraPreview: NSObject {
    private var session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
        super.init()
    }
    
    public func configurePreview(container: CALayer) -> AVCaptureVideoPreviewLayer{
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect // // Preserve aspect ratio; fit within layer bounds;
        previewLayer.frame = container.bounds
        previewLayer.contentsGravity = kCAGravityResizeAspectFill
        return previewLayer
    }
    
    public func addPreview(container: CALayer, previewLayer: AVCaptureVideoPreviewLayer){
        container.insertSublayer(previewLayer, at: 0)
    }
    
    public func removePreview(previewLayer: AVCaptureVideoPreviewLayer){
        previewLayer.removeFromSuperlayer()
    }
}
