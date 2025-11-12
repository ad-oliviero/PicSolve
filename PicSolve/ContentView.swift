//
//  ContentView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 07/11/25.
//

import PhotosUI
import SwiftUI
internal import Combine

struct ContentView: View {
    @State var showPhotoPicker: Bool = false
    @StateObject var viewModel: PhotoSelectorViewModel = .init()
    @State private var camera = CameraModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        TabView {
            Tab("Camera", systemImage: "camera") {
                CameraView(camera: camera)
//                    .statusBarHidden(false)
                    .task {
                        await camera.start()
                    }
            }
            Tab("Manual", systemImage: "keyboard.fill") {
                VStack {
                    if viewModel.image != nil {
                        Image(uiImage: viewModel.image!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300)
                    }
                    Button("Load a Picture") {
                        showPhotoPicker.toggle()
                    }
                    .buttonStyle(.glassProminent)
                    .photosPicker(isPresented: $showPhotoPicker,
                                  selection: $viewModel.selectedPhotos,
                                  maxSelectionCount: 1,
                                  selectionBehavior: .ordered,
                                  matching: .images)
                    ScrollView(.vertical) {
                        VStack {
                            ForEach($viewModel.croppedImages.indices, id: \.self) { index in
                                Image(uiImage: viewModel.croppedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .border(Color.blue, width: 2)
                            }
                        }
                    }
                    Button("Solve") {}
                        .buttonStyle(.glassProminent)
                }
                .onChange(of: viewModel.selectedPhotos) { _, _ in
                    viewModel.convertDataToImage()
                }
            }
        }
    }
}

class PhotoSelectorViewModel: ObservableObject {
    #if DEBUG
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

#Preview {
    ContentView()
}
