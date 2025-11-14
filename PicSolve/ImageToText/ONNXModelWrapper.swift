//
//  ONNXModelWrapper.swift
//  PicSolve
//
//  Created by Adriano Oliviero (AI actually, I can't read Obj-C) on 14/11/25.
//

import Foundation
import OnnxRuntimeBindings
import UIKit

enum ONNXModelError: Error {
    case modelNotFound
    case sessionCreationFailed
    case inferenceError(String)
    case preprocessingError
}

class ONNXModelWrapper {
    private var ortEnv: ORTEnv?
    private var ortSession: ORTSession?
    private let modelName: String
    private let modelExtension: String
    
    init(modelName: String, modelExtension: String = "onnx") {
        self.modelName = modelName
        self.modelExtension = modelExtension
    }
    
    func loadModel() throws {
        // Create ONNX Runtime environment
        ortEnv = try ORTEnv(loggingLevel: .warning)
        
        // Find model path in bundle
        guard let modelPath = Bundle.main.path(forResource: modelName, ofType: modelExtension) else {
            throw ONNXModelError.modelNotFound
        }
        
        // Create session options with optimizations
        let options = try ORTSessionOptions()
        try options.setGraphOptimizationLevel(.all)
        try options.setIntraOpNumThreads(2)
        
        // Create session
        guard let env = ortEnv else {
            throw ONNXModelError.sessionCreationFailed
        }
        
        ortSession = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
        
        print("ONNX Model '\(modelName)' loaded successfully from: \(modelPath)")
    }
    
    func getInputNames() throws -> [String] {
        guard let session = ortSession else {
            throw ONNXModelError.sessionCreationFailed
        }
        
        let inputNames = try session.inputNames()
        print("Model inputs: \(inputNames)")
        return inputNames
    }
    
    func getOutputNames() throws -> [String] {
        guard let session = ortSession else {
            throw ONNXModelError.sessionCreationFailed
        }
        
        let outputNames = try session.outputNames()
        print("Model outputs: \(outputNames)")
        return outputNames
    }
    
    // Basic inference example with float array input
    func runInference(inputs: [String: ORTValue]) throws -> [String: ORTValue] {
        guard let session = ortSession else {
            throw ONNXModelError.sessionCreationFailed
        }
        
        // Get output names and convert to Set
        let outputNames = try session.outputNames()
        let outputNamesSet = Set(outputNames)
        
        // Run inference with output names specified
        let outputs = try session.run(withInputs: inputs, outputNames: outputNamesSet, runOptions: nil)
        
        return outputs
    }
    
    // Helper to create tensor from image
    func createTensorFromImage(_ image: UIImage, targetSize: CGSize) throws -> ORTValue {
        guard let pixelBuffer = image.pixelBuffer(width: Int(targetSize.width), height: Int(targetSize.height)) else {
            throw ONNXModelError.preprocessingError
        }
        
        // Convert pixel buffer to normalized float array
        let floatArray = try pixelBufferToFloatArray(pixelBuffer)
        
        // Create shape [batch, channels, height, width]
        let shape: [NSNumber] = [1, 3, NSNumber(value: Int(targetSize.height)), NSNumber(value: Int(targetSize.width))]
        
        guard ortEnv != nil else {
            throw ONNXModelError.sessionCreationFailed
        }
        
        let tensor = try ORTValue(tensorData: NSMutableData(data: Data(bytes: floatArray, count: floatArray.count * MemoryLayout<Float>.stride)),
                                  elementType: .float,
                                  shape: shape)
        
        return tensor
    }
    
    private func pixelBufferToFloatArray(_ pixelBuffer: CVPixelBuffer) throws -> [Float] {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ONNXModelError.preprocessingError
        }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let totalPixels = width * height
        var floatArray = [Float](repeating: 0, count: totalPixels * 3)
        
        // ImageNet normalization values
        let mean: [Float] = [0.485, 0.456, 0.406]
        let std: [Float] = [0.229, 0.224, 0.225]
        
        // Single-pass conversion: BGRA to CHW format with normalization
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let pixelIndex = y * width + x
                
                let b = Float(buffer[offset]) / 255.0
                let g = Float(buffer[offset + 1]) / 255.0
                let r = Float(buffer[offset + 2]) / 255.0
                
                // Store in CHW format (all R, then all G, then all B)
                floatArray[pixelIndex] = (r - mean[0]) / std[0]
                floatArray[totalPixels + pixelIndex] = (g - mean[1]) / std[1]
                floatArray[totalPixels * 2 + pixelIndex] = (b - mean[2]) / std[2]
            }
        }
        
        return floatArray
    }
}

// Helper extension for UIImage
extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        guard let cgImage = cgImage, let ctx = context else {
            return nil
        }
        
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }
}
