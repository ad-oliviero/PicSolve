//
//  SolveView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 13/11/25.
//

import SwiftUI

struct SolveView: View {
    @StateObject var photoSelector: PhotoSelectorViewModel
    @State private var showBoundingBoxes = true

    var body: some View {
        VStack {
            if let image = photoSelector.image {
                ZStack {
                    Image(uiImage: image).resizable().scaledToFit()
//                    FormulaOverlayPreview(image: image, results: photoSelector.formulaResults)
                }
            }
//            if showBoundingBoxes {
//                FormulaOverlayPreview(image: , results: )
//            }
        }
        .navigationTitle("Solution")
    }
//        .task { await photoSelector.processFormulas() }
}

#Preview {
    NavigationStack {
        SolveView(photoSelector: PhotoSelectorViewModel())
    }.preferredColorScheme(.dark)
}
