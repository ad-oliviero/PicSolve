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

    init() {
        try! model.loadModel()
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

        for i in 0 ..< numDetections {
            let offset = i * 6
            let xCenter = floatArray[offset]
            let yCenter = floatArray[offset + 1]
            let width = floatArray[offset + 2]
            let height = floatArray[offset + 3]
            let confidence = floatArray[offset + 4]
            let classId = Int(floatArray[offset + 5])

            if confidence > 0.5 {
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
        return boxes
    }

    func processImage(from: UIImage) throws -> [BoundingBox] {
        image = from
        let inputs = try prepareInput()
        let outputs = try model.runInference(inputs: inputs)

        return try processOutputs(outputs: outputs)
    }
}
