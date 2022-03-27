//
//  ViewController+Vision.swift
//  Image Analyzer
//
//  Created by Nicholas McGinnis on 3/27/22.
//

import UIKit
import Vision

extension ViewController {
    func performVisionRequest(image: UIImage) {
        var detectionRequest: VNDetectRectanglesRequest {
            let request = VNDetectRectanglesRequest { (request, error) in
                if let detectError = error as NSError? {
                    print(detectError)
                    return
                } else {
                    guard let observations = request.results as? [VNDetectedObjectObservation] else {
                        return
                    }
                    print(observations)
                    self.visualizeObservations(observations)
                }
            }
            request.maximumObservations = 0
            request.minimumConfidence = 0.1
            request.minimumAspectRatio = 0.1
            return request
        }
        
        guard let cgImage = image.cgImage else { return }
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgOrientation, options: [:])
        let requests = [detectionRequest]
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
    
    private func visualizeObservations(_ observations: [VNDetectedObjectObservation]) {
        DispatchQueue.main.async {
            guard let image = self.imageView.image else {
                print("Failed to retrieve image")
                return
            }
            let imageSize = image.size
            var transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -imageSize.height)
            transform = transform.scaledBy(x: imageSize.width, y: imageSize.height)
            
            UIGraphicsBeginImageContextWithOptions(imageSize, true, 0.0)
            let context = UIGraphicsGetCurrentContext()
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            
            context?.saveGState()
            
            context?.setLineWidth(8.0)
            context?.setLineJoin(CGLineJoin.round)
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.3)
            
            observations.forEach({ (observations) in
                let observationsBounds = observations.boundingBox.applying(transform)
                context?.addRect(observationsBounds)
            })
            
            context?.drawPath(using: CGPathDrawingMode.fillStroke)
            context?.restoreGState()
            
            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            self.imageView.image = drawnImage
        }
    }
}
