//
//  ImageProcessor.swift
//  WorldAloud
//
//  Created by Andre Guerra on 21/12/17.
//  Copyright © 2017 Andre Guerra. All rights reserved.
//

import UIKit
import CoreImage

/// A collection of image manipulation routines, which require no instance to run (static).
class ImageProcessor: NSObject {
    private static let context = CIContext(options: nil) // context for all CIImages here.
    
    /// Rotates an input image at a given counterclockwise angle
    ///
    /// - Parameters:
    ///   - image: the input image you want to rotate
    ///   - angleCCW: counterclockwise angle in radians, negative values rotate clockwise
    /// - Returns: rotated CIImage
    public static func rotateImage(_ image: CIImage, angle: CGFloat) -> CIImage? {
        let transform = CGAffineTransform.init(rotationAngle: angle)
        return self.affineTransform(image: image, transform: transform)
    }
    
    public static func translateImage(_ image: CIImage, horizontalTranslation: CGFloat, verticalTranslation: CGFloat) -> CIImage? {
        let transform = CGAffineTransform.init(translationX: horizontalTranslation, y: verticalTranslation)
        return self.affineTransform(image: image, transform: transform)
    }
    
    public static func applyColorCorrection(image: CIImage, saturation: CGFloat, contrast: CGFloat) -> CIImage? {
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
    
    public static func cropImage(_ image: CIImage, cropRectangle: CGRect) -> CIImage? {
        guard let filter = CIFilter(name: "CICrop",
                                    withInputParameters: ["inputImage":image,
                                                          "inputRectangle":cropRectangle])
            else {
                print("Unable generate filter.")
                return nil
        }
        return self.generateImageFromFilter(filter)
    }
    
    /// As the Vision framework outputs normalized rectangles, which values for x, y, width and height range from [0:1], we need to adapt these to the absolute coordinates of an image before applying a crop, for example, to it.
    ///
    /// - Parameters:
    ///   - image: a CIImage which dimensions will be used to convert from normalized to absolute values
    ///   - normalRectangle: a normalized rectangle
    /// - Returns: Absolute rectangle
    public static func getAbsoluteRectangleFromNormalized(image: CIImage, normalRectangle: CGRect) -> CGRect {
        return CGRect(x: normalRectangle.origin.x * image.extent.width,
                      y: normalRectangle.origin.y * image.extent.height,
                      width: normalRectangle.width * image.extent.width,
                      height: normalRectangle.height * image.extent.height)
    }
    
    private static func affineTransform(image: CIImage, transform: CGAffineTransform) -> CIImage? {
        guard let filter = CIFilter(name: "CIAffineTransform",
                                    withInputParameters: ["inputImage":image,
                                                          "inputTransform":transform])
            else {
                print("Unable generate filter.")
                return nil
        }
        return self.generateImageFromFilter(filter)
    }
    
    private static func generateImageFromFilter(_ filter: CIFilter) -> CIImage? {
        if let result = filter.outputImage {
            return result
        } else {
            return nil
        }
    }
}
