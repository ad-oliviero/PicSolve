//
//  MathFormulaRecognizer.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 14/11/25.
//

import OnnxRuntimeBindings
import SwiftUI

class MathFormulaRecognizer {
    private var croppedImage: UIImage?
    private let encoderModel = ONNXModelWrapper(modelName: "encoder_model")
    private let decoderModel = ONNXModelWrapper(modelName: "decoder_model")

    init() {
        try! encoderModel.loadModel()
        try! decoderModel.loadModel()
    }

    private func prepareMFREncoderInput() throws -> [String: ORTValue] {
        // according to to their repository, the models accepts 384x384 images
        let targetSize = CGSize(width: 384, height: 384)

        // Normalize with mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5]
        // This is different from ImageNet! You'll need to modify ONNXModelWrapper
        // Or create a custom preprocessing function
        let tensor = try prepareMFRTensor(image: croppedImage!, size: targetSize)

        // also, the input name is "pixel_values"
        return ["pixel_values": tensor]
    }

    private func prepareMFRTensor(image: UIImage, size: CGSize) throws -> ORTValue {
        // get a 384x384 pixel buffer
        guard let pixelBuffer = image.pixelBuffer(width: Int(size.width), height: Int(size.height)) else {
            throw ONNXModelError.preprocessingError
        }

        // no idea about this. it was too complex for me to understand
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ONNXModelError.preprocessingError
        }

        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var floatArray = [Float]()
        floatArray.reserveCapacity(width * height * 3)

        // MFR normalization: mean=0.5, std=0.5 for all channels
        // Formula: (pixel / 255.0 - 0.5) / 0.5 = (pixel / 255.0 - 0.5) * 2

        // R channel
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let r = Float(buffer[offset + 2]) / 255.0
                floatArray.append((r - 0.5) * 2.0)
            }
        }

        // G channel
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let g = Float(buffer[offset + 1]) / 255.0
                floatArray.append((g - 0.5) * 2.0)
            }
        }

        // B channel
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let b = Float(buffer[offset]) / 255.0
                floatArray.append((b - 0.5) * 2.0)
            }
        }

        // Create tensor [1, 3, 384, 384]
        let shape: [NSNumber] = [1, 3, NSNumber(value: height), NSNumber(value: width)]

        let tensor = try ORTValue(
            tensorData: NSMutableData(data: Data(bytes: floatArray, count: floatArray.count * MemoryLayout<Float>.stride)),
            elementType: .float,
            shape: shape
        )

        return tensor
    }

    private func processMFREncoder(outputs: [String: ORTValue]) throws -> ORTValue {
        // according to the repo, the encoder outputs "hidden states"
        guard let encoderOutput = outputs["last_hidden_state"] else {
            throw NSError(domain: "MFR", code: 2, userInfo: [NSLocalizedDescriptionKey: "Encoder output not found"])
        }
        return encoderOutput
    }

    private func prepareMFRDecoderInput(inputIds: [Int], encoderHiddenStates: ORTValue) throws -> [String: ORTValue] {
        // "input_ids": [1, seq_len]
        // "encoder_hidden_states": [1, 577, 384] - from encoder

        let inputIdsData = inputIds.map { Int64($0) }
        let inputIdsTensor = try ORTValue(
            tensorData: NSMutableData(data: Data(bytes: inputIdsData, count: inputIdsData.count * MemoryLayout<Int64>.stride)),
            elementType: .int64,
            shape: [1, NSNumber(value: inputIds.count)]
        )

        return [
            "input_ids": inputIdsTensor,
            "encoder_hidden_states": encoderHiddenStates
        ]
    }

    func getNextToken(from outputs: [String: ORTValue]) throws -> Int {
        // Decoder output: "logits" with shape [1, seq_len, vocab_size]
        // We want the last token's logits: [vocab_size]

        guard let logits = outputs["logits"] else {
            throw NSError(domain: "MFR", code: 3, userInfo: [NSLocalizedDescriptionKey: "Logits not found"])
        }

        let logitsData = try logits.tensorData() as Data
        let floatArray = logitsData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        // Get last token's logits (vocab_size = 1868)
        let vocabSize = 1868
        let lastTokenLogits = Array(floatArray.suffix(vocabSize))

        // Find argmax
        let maxIndex = lastTokenLogits.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0

        return maxIndex
    }

    func loadTokenizer() throws -> [Int: String] {
        let path = Bundle.main.path(forResource: "tokenizer", ofType: "json")!

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let model = json["model"] as! [String: Any]
        let vocab = model["vocab"] as! [String: Int]

        var idToToken: [Int: String] = [:]
        for (token, id) in vocab {
            idToToken[id] = token
        }

        return idToToken
    }

    func tokensToLatex(_ tokens: [Int]) throws -> String {
        let tokenizer = try loadTokenizer()

        var latex = ""
        for token in tokens {
            if token == 0 || token == 1 || token == 2 { continue }

            if let tokenStr = tokenizer[token] {
                latex += tokenStr
            }
        }

        // The Ġ character (U+0120) represents spaces in GPT-style tokenizers
        latex = latex.replacingOccurrences(of: "Ġ", with: " ")
        latex = latex.trimmingCharacters(in: .whitespaces)

        return latex
    }

    func recognize(from: UIImage) throws -> String {
        croppedImage = from
        let encoderInputs = try prepareMFREncoderInput()
        let encoderOutputs = try encoderModel.runInference(inputs: encoderInputs)
        let encoderHiddenStates = try processMFREncoder(outputs: encoderOutputs)

        var decodedTokens = [1] // Start with <bos> token (id=1)
        let maxLength = 512
        let eosTokenId = 2 // <eos> token

        for _ in 0..<maxLength {
            let decoderInputs = try prepareMFRDecoderInput(
                inputIds: decodedTokens,
                encoderHiddenStates: encoderHiddenStates
            )

            let decoderOutputs = try decoderModel.runInference(inputs: decoderInputs)
            let nextToken = try getNextToken(from: decoderOutputs)

            decodedTokens.append(nextToken)

            // Stop if we hit <eos>
            if nextToken == eosTokenId {
                break
            }
        }

        return try tokensToLatex(decodedTokens)
    }
}
