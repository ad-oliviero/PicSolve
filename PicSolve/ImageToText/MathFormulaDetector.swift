//
//  MathFormulaDetector.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 14/11/25.
//

import OnnxRuntimeBindings
import SwiftUI

struct BoundingBox {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
    let confidence: Float
    let classId: Int
}

class MathFormulaDetector {
    private var image: UIImage?
    private let model = ONNXModelWrapper(modelName: "pix2text-mfd-1.5")
    private var isModelLoaded = false

    private func ensureModelLoaded() throws {
        if !isModelLoaded {
            try model.loadModel()
            isModelLoaded = true
        }
    }

    private func prepareInput() throws -> [String: ORTValue] {
        // according to their repository, the models accept 768x768 images
        let targetSize = CGSize(width: 768, height: 768)
        let tensor = try model.createTensorFromImage(image!, targetSize: targetSize)

        // also, the input name is "images"
        return ["images": tensor]
    }

    private func processOutputs(outputs: [String: ORTValue]) throws -> [BoundingBox] {
        guard let output = outputs["output0"] else {
            throw NSError(domain: "MFD", code: 1, userInfo: [NSLocalizedDescriptionKey: "Output not found"])
        }

        let tensorData = try output.tensorData() as Data
        let floatArray = tensorData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        var boxes: [BoundingBox] = []
        let numDetections = floatArray.count / 6
        let confidenceThreshold: Float = 150.0

        for i in 0 ..< numDetections {
            let offset = i * 6
            let xCenter = floatArray[offset]
            let yCenter = floatArray[offset + 1]
            let width = floatArray[offset + 2]
            let height = floatArray[offset + 3]
            let confidence = floatArray[offset + 4]
            let classId = Int(floatArray[offset + 5])

            if confidence > confidenceThreshold {
                let x = xCenter - width / 2
                let y = yCenter - height / 2

                boxes.append(BoundingBox(
                    x: x, y: y,
                    width: width, height: height,
                    confidence: confidence,
                    classId: classId
                ))
            }
        }

        // Sort by confidence descending
        boxes.sort { $0.confidence > $1.confidence }

        print("Found \(boxes.count) high-confidence detections")

        // Apply NMS
        boxes = nonMaximumSuppression(boxes: boxes, iouThreshold: 0.3)

        // Return only the second best detection (index 1) if it exists, otherwise the best
        if boxes.count >= 2 {
            return [boxes[1]]
        } else if !boxes.isEmpty {
            return [boxes[0]]
        }

        return []
    }

    private func nonMaximumSuppression(boxes: [BoundingBox], iouThreshold: Float) -> [BoundingBox] {
        // Sort by confidence (descending)
        let sortedBoxes = boxes.sorted { $0.confidence > $1.confidence }
        var selected: [BoundingBox] = []
        var suppressed = Set<Int>()

        for (i, box) in sortedBoxes.enumerated() {
            if suppressed.contains(i) { continue }

            selected.append(box)

            // Suppress overlapping boxes
            for (j, otherBox) in sortedBoxes.enumerated() where j > i {
                if suppressed.contains(j) { continue }

                let iou = calculateIOU(box, otherBox)
                if iou > iouThreshold {
                    suppressed.insert(j)
                }
            }
        }

        return selected
    }

    private func calculateIOU(_ box1: BoundingBox, _ box2: BoundingBox) -> Float {
        let x1 = max(box1.x, box2.x)
        let y1 = max(box1.y, box2.y)
        let x2 = min(box1.x + box1.width, box2.x + box2.width)
        let y2 = min(box1.y + box1.height, box2.y + box2.height)

        let intersectionWidth = max(0, x2 - x1)
        let intersectionHeight = max(0, y2 - y1)
        let intersectionArea = intersectionWidth * intersectionHeight

        let area1 = box1.width * box1.height
        let area2 = box2.width * box2.height
        let unionArea = area1 + area2 - intersectionArea

        return unionArea > 0 ? intersectionArea / unionArea : 0
    }

    func processImage(from: UIImage) throws -> [BoundingBox] {
        try ensureModelLoaded()
        image = from
        let inputs = try prepareInput()
        let outputs = try model.runInference(inputs: inputs)

        return try processOutputs(outputs: outputs)
    }
}
