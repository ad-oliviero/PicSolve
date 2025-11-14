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
    @State private var textResult: String?

    var body: some View {
        VStack {
            if let image = photoSelector.image {
                Image(uiImage: image).resizable().scaledToFit()
            }

            if let result = textResult {
                LaTeX("$$" + result + "$$")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ProgressView()
            }
            Spacer()
        }
        .navigationTitle("Solution")
        .onAppear {
            Task {
                if let image = photoSelector.image {
                    let provider = Pix2TextProvider()

                    do {
                        let results = try provider.run(from: image)

                        if results.isEmpty {
                            textResult = "No formulas detected in the image."
                        } else {
                            textResult = results[0].1
                        }
                    } catch {
                        textResult = "No formulas detected in the image."
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SolveView(photoSelector: PhotoSelectorViewModel())
    }.preferredColorScheme(.dark)
}
