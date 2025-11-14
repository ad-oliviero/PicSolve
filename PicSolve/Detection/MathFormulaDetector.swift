//
//  MathFormulaDetector.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 14/11/25.
//

import Foundation

struct DetectionBox {
    let type: String
    let box: [[CGFloat]]
    let score: Float
    let normalizedBox: CGRect
}

struct FormulaResult: Identifiable {
    let id = UUID()
    let type: String
    let position: [[CGFloat]]
    let normalizedBox: CGRect
    let text: String
    let score: Float
    let detectionScore: Float
}
