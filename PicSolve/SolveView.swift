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
    private let pix2textProvider: Pix2TextProvider = .init()
    @State private var textResult: String?

    var body: some View {
        VStack {
            if let image = photoSelector.image {
                Image(uiImage: image).resizable().scaledToFit()
            }
            if let result = textResult {
                Text(result)
            }
        }
        .navigationTitle("Solution")
        .onAppear {
            if let image = photoSelector.image {
                let results = try! pix2textProvider.run(from: image)
                print(results)
            } else {
                fatalError("Failed to load image")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SolveView(photoSelector: PhotoSelectorViewModel())
    }.preferredColorScheme(.dark)
}
