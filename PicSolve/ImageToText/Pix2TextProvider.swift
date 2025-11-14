//
//  Pix2TextProvider.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 14/11/25.
//

import SwiftUI

class Pix2TextProvider {
    var image: UIImage?
    private var mfDetector = MathFormulaDetector()
    private var mfRecognizer = MathFormulaRecognizer()

    func run(from: UIImage) throws -> [(BoundingBox, String)] {
        self.image = from

        let boxes = try mfDetector.processImage(from: self.image!)
        let croppedImages = try cropFormulaRegions(boxes: boxes)

        var results: [(BoundingBox, String)] = []

        for (box, croppedImage) in zip(boxes, croppedImages) {
            print("Box: \(box)")
            print("Cropped image size: \(croppedImage.size)")
            let text = try mfRecognizer.recognize(from: croppedImage)
            results.append((box, text))
        }

        return results
    }

    private func cropFormulaRegions(boxes: [BoundingBox]) throws -> [UIImage] {
        var croppedImages: [UIImage] = []

        guard let cgImage = image!.cgImage else { return [] }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        for box in boxes {
            let x = CGFloat(box.x) * imageWidth
            let y = CGFloat(box.y) * imageHeight
            let width = CGFloat(box.width) * imageWidth
            let height = CGFloat(box.height) * imageHeight

            let rect = CGRect(x: x, y: y, width: width, height: height)

            if let croppedCGImage = cgImage.cropping(to: rect) {
                croppedImages.append(UIImage(cgImage: croppedCGImage))
            }
        }

        return croppedImages
    }
}
