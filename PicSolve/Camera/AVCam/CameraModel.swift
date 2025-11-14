/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 An object that provides the interface to the features of the camera.
 */

import Combine
import os
import SwiftUI

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@MainActor
@Observable
final class CameraModel: Camera {
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown

    /// The current state of photo or movie capture.
    private(set) var captureActivity = CaptureActivity.idle

    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false

    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    private(set) var shouldFlashScreen = false

    /// An error that indicates the details of an error during photo or movie capture.
    private(set) var error: Error?

    /// The data of the last captured photo.
    private(set) var lastCapturedPhotoData: Data?

    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }

    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()

    /// Persistent state shared between the app and capture extension.
    private var cameraState = CameraState()

    init() {
        //
    }

    // MARK: - Starting the camera

    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use device cameras and microphones.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start(with: cameraState)
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }

    // MARK: - Changing modes and devices

    /// A value that indicates the mode of capture for the camera.
    var captureMode = CaptureMode.photo

    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        captureService.selectNextVideoDevice()
    }

    // MARK: - Photo capture

    /// Captures a photo and writes it to the user's Photos library.
    func capturePhoto() async -> Data? {
        do {
            let photoFeatures = PhotoFeatures(qualityPrioritization: .balanced)
            let photo = try await captureService.capturePhoto(with: photoFeatures)
            lastCapturedPhotoData = photo.data
            return lastCapturedPhotoData
        } catch {
            self.error = error
        }
        return nil
    }

    /// A value that indicates how to balance the photo capture quality versus speed.
    var qualityPrioritization = QualityPrioritization.quality {
        didSet {
            // Update the persistent state value.
            cameraState.qualityPrioritization = qualityPrioritization
        }
    }

    /// Performs a focus and expose operation at the specified screen point.
    func focusAndExpose(at point: CGPoint) async {
        captureService.focusAndExpose(at: point)
    }

    // MARK: - Internal state observations

    // Set up camera's state observations.
    private func observeState() {
        // No longer observing capture activity from capture service.
        // captureActivity will be updated directly when capturePhoto() is called.
    }
}
