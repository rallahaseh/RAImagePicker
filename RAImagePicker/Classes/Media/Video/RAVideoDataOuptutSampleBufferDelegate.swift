//
//  RAVideoDataOuptutSampleBufferDelegate.swift
//  RAImagePicker
//
//  Created by Rashed Al Lahaseh on 11/29/17.
//

import Foundation
import AVFoundation


// Note: if video file output is provided, video data output is not working!!! there must be only 1 output at the same time
final class RAVideoOutputSampleBufferDelegate : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let processQueue = DispatchQueue(label: "video-output-sample-buffer-delegate.queue")
    
    var latestImage: UIImage? {
        return latestSampleBuffer?.imageRepresentation
    }
    
    private var latestSampleBuffer: CMSampleBuffer?
    
    @nonobjc func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestSampleBuffer = sampleBuffer
    }
    
    @nonobjc func captureOutput(captureOutput: AVCaptureFileOutput, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL, fromConnections connections: [AnyObject], error: NSError!) {
    }
}

extension CMSampleBuffer {
    
    static let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
    
    // Converts sample buffer to UIImage with backing CGImage
    fileprivate var imageRepresentation: UIImage? {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Down Scale Image
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(0.25, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let resizedCiImage = filter.value(forKey: "outputImage") as! CIImage
        
        
        // We need to convert CIImage to CGImage because we are using Apples blurring functions
        // This conversion is very expensive, use it only when you really need it
        if let cgImage = CMSampleBuffer.context.createCGImage(resizedCiImage, from: resizedCiImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}
