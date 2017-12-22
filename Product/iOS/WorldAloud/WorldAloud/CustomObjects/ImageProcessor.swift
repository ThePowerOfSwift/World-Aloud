//
//  ImageProcessor.swift
//  WorldAloud
//
//  Created by Andre Guerra on 21/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import CoreImage

class ImageProcessor: NSObject {
    private let context = CIContext(options: nil) // context for all CIImages here.
    
    public func rotateImage(_ image: CIImage, angle: CGFloat) -> CIImage? {
        let transform = CGAffineTransform.init(rotationAngle: angle)
        return self.affineTransform(image: image, transform: transform)
    }
    
    public func translateImage(_ image: CIImage, horizontalTranslation: CGFloat, verticalTranslation: CGFloat) -> CIImage? {
        let transform = CGAffineTransform.init(translationX: horizontalTranslation, y: verticalTranslation)
        return self.affineTransform(image: image, transform: transform)
    }
    
    public func applyColorCorrection(image: CIImage, saturation: CGFloat, contrast: CGFloat) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls",
                                    withInputParameters: ["inputImage":image,
                                                          "inputSaturation":saturation,
                                                          "inputContrast":contrast])
            else {
                print("Unable to create color correction filter.")
                return nil
        }
        return self.generateImageFromFilter(filter)
    }
    
    public func cropImage(_ image: CIImage, cropRectangle: CGRect) -> CIImage? {
        guard let filter = CIFilter(name: "CICrop",
                                    withInputParameters: ["inputImage":image,
                                                          "inputRectangle":cropRectangle])
            else {
                print("Unable generate filter.")
                return nil
        }
        return self.generateImageFromFilter(filter)
    }
    
    private func affineTransform(image: CIImage, transform: CGAffineTransform) -> CIImage? {
        guard let filter = CIFilter(name: "CIAffineTransform",
                                    withInputParameters: ["inputImage":image,
                                                          "inputTransform":transform])
            else {
                print("Unable generate filter.")
                return nil
        }
        return self.generateImageFromFilter(filter)
    }
    
    private func generateImageFromFilter(_ filter: CIFilter) -> CIImage? {
        if let result = filter.outputImage {
            return result
        } else {
            return nil
        }
    }
}
