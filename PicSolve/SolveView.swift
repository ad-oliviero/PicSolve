//
//  SolveView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 13/11/25.
//

import SwiftUI

struct SolveView: View {
    @StateObject var photoSelector: PhotoSelectorViewModel

    var body: some View {
        if let image = photoSelector.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .navigationTitle("Solution")
        }
    }
}

#Preview {
    SolveView(photoSelector: PhotoSelectorViewModel())
}
