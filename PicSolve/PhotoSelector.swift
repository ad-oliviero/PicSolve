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
    @Published var imageData: Data?

    @MainActor
    func convertDataToImage() {
        if !selectedPhotos.isEmpty {
            Task {
                if let data = try? await selectedPhotos[0].loadTransferable(type: Data.self) {
                    self.imageData = data
                    if let currentimage = UIImage(data: data) {
                        image = currentimage
                        selectedPhotos.removeAll()
                    }
                }
            }
        } else if imageData != nil {
            if let currentimage = UIImage(data: imageData!) {
                image = currentimage
            }
        }
    }
}
