//
//  Pix2TextProvider.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 14/11/25.
//

import SwiftUI

class Pix2TextProvider {
    var image: UIImage?
    private lazy var mfDetector = MathFormulaDetector()
    private lazy var mfRecognizer = MathFormulaRecognizer()

    func run(from: UIImage) throws -> [(BoundingBox, String)] {
        self.image = from

        let boxes = try mfDetector.processImage(from: self.image!)

        guard !boxes.isEmpty else {
            print("No math formulas detected in image")
            return []
        }

        let boxesAndImages = try cropFormulaRegions(boxes: boxes)

        guard !boxesAndImages.isEmpty else {
            print("No valid regions to process after cropping")
            return []
        }

        var results: [(BoundingBox, String)] = []

        for (box, croppedImage) in boxesAndImages {
            autoreleasepool {
                do {
                    let text = try mfRecognizer.recognize(from: croppedImage)
                    results.append((box, text))
                } catch {
                    print("Error recognizing formula: \(error)")
                }
            }
        }

        return results
    }

    private func cropFormulaRegions(boxes: [BoundingBox]) throws -> [(BoundingBox, UIImage)] {
        var results: [(BoundingBox, UIImage)] = []

        guard let cgImage = image!.cgImage else { return [] }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        for box in boxes {
            let x = CGFloat(box.x) / 768.0 * imageWidth
            let y = CGFloat(box.y) / 768.0 * imageHeight
            let width = CGFloat(box.width) / 768.0 * imageWidth
            let height = CGFloat(box.height) / 768.0 * imageHeight

            // box coordinates: raw \(box.x),\(box.y) -> scaled \(x),\(y)

            // Validate and clamp bounding box coordinates
            let clampedX = max(0, min(x, imageWidth))
            let clampedY = max(0, min(y, imageHeight))
            let clampedWidth = min(width, imageWidth - clampedX)
            let clampedHeight = min(height, imageHeight - clampedY)

            // skip non valid boxes
            if clampedWidth <= 0 || clampedHeight <= 0 {
                continue
            }

            let rect = CGRect(x: clampedX, y: clampedY, width: clampedWidth, height: clampedHeight)

            if let croppedCGImage = cgImage.cropping(to: rect) {
                results.append((box, UIImage(cgImage: croppedCGImage)))
            }
        }

        return results
    }
}
