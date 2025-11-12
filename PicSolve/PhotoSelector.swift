//
//  PhotoSelector.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 12/11/25.
//

import PhotosUI
import SwiftUI
internal import Combine

class PhotoSelectorViewModel: ObservableObject {
    #if targetEnvironment(simulator)
        @Published var image: UIImage? = UIImage(named: "sampleEquation")
    #else
        @Published var image: UIImage?
    #endif
    @Published var selectedPhotos = [PhotosPickerItem]()
    @Published var croppedImages: [UIImage] = []

    @MainActor
    func convertDataToImage() {
        if !selectedPhotos.isEmpty {
            Task {
                if let imageData = try? await selectedPhotos[0].loadTransferable(type: Data.self) {
                    if let currentimage = UIImage(data: imageData) {
                        image = currentimage
                        selectedPhotos.removeAll()
                    }
                }
            }
        }
    }
}
