//
//  CornerRectangle.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 12/11/25.
//

import SwiftUI

struct CornerRectangle: Shape {
    let cornerLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.addLines([
            .init(x: rect.minX, y: rect.minY + cornerLength),
            .init(x: rect.minX, y: rect.minY),
            .init(x: rect.minX + cornerLength, y: rect.minY),
        ])

        path.addLines([
            .init(x: rect.maxX - cornerLength, y: rect.minY),
            .init(x: rect.maxX, y: rect.minY),
            .init(x: rect.maxX, y: rect.minY + cornerLength),
        ])

        path.addLines([
            .init(x: rect.maxX, y: rect.maxY - cornerLength),
            .init(x: rect.maxX, y: rect.maxY),
            .init(x: rect.maxX - cornerLength, y: rect.maxY),
        ])

        path.addLines([
            .init(x: rect.minX + cornerLength, y: rect.maxY),
            .init(x: rect.minX, y: rect.maxY),
            .init(x: rect.minX, y: rect.maxY - cornerLength),
        ])

        return path
    }
}
