//
//  SolveView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 13/11/25.
//

import LaTeXSwiftUI
import SwiftUI

struct SolveView: View {
    @StateObject var photoSelector: PhotoSelectorViewModel
    @State private var showBoundingBoxes = true
    @State private var pix2textProvider: Pix2TextProvider?
    @State private var textResult: String?

    var body: some View {
        VStack {
            if let image = photoSelector.image {
                Image(uiImage: image).resizable().scaledToFit()
            }

            if let result = textResult {
                ScrollView {
                    LaTeX("$$" + result + "$$")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle("Solution")
        .onAppear {
            if let image = photoSelector.image {
                if pix2textProvider == nil {
                    pix2textProvider = Pix2TextProvider()
                }

                do {
                    let results = try pix2textProvider!.run(from: image)

                    if results.isEmpty {
                        textResult = "No formulas detected in the image."
                    } else {
                        textResult = results[0].1
                    }
                } catch {
                    textResult = "No formulas detected in the image."
                    fatalError("Failed to extract text from the image")
                }
            } else {
                fatalError("No image to process")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SolveView(photoSelector: PhotoSelectorViewModel())
    }.preferredColorScheme(.dark)
}
