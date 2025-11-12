/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 An object that manages a photo capture output to take photographs.
 */

import AVFoundation
import CoreImage
import os

enum PhotoCaptureError: Error {
    case noPhotoData
    case notReady
    case simulatorUnsupported
    case timedOut
}

/// An object that manages a photo capture output to perform take photographs.
@MainActor
final class PhotoCapture: OutputService {
    /// The capture output type for this service.
    let output = AVCapturePhotoOutput()

    // An internal alias for the output.
    private var photoOutput: AVCapturePhotoOutput { output }

    // Keep strong references to in-flight delegates until they finish.
    private var inFlightDelegates = Set<PhotoCaptureDelegate>()

    // MARK: - Capture a photo.

    /// The app calls this method when the user taps the photo capture button.
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        #if targetEnvironment(simulator)
        throw PhotoCaptureError.simulatorUnsupported
        #else
        // Basic precondition: ensure there is at least one active connection.
        guard photoOutput.connections.contains(where: { $0.isActive }) else {
            throw PhotoCaptureError.notReady
        }

        // Create the settings prior to the continuation so we can throw early if needed.
        let photoSettings = createPhotoSettings(with: features)

        // Race the capture with a timeout to prevent leaks if callbacks never arrive.
        return try await withThrowingTaskGroup(of: Photo.self) { group in
            // Main capture task (runs on the main actor because this method is @MainActor)
            group.addTask { @MainActor in
                try await withTaskCancellationHandler(operation: {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Photo, Error>) in
                        let delegate = PhotoCaptureDelegate(
                            continuation: continuation,
                            onFinish: { [weak self] delegate in
                                self?.inFlightDelegates.remove(delegate)
                            }
                        )
                        // Keep delegate alive for the duration of capture.
                        self.inFlightDelegates.insert(delegate)
                        // Start capture.
                        self.photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
                    }
                }, onCancel: {
                    // Nothing to do here; the continuation will be resumed when the operation block exits if needed.
                })
            }

            // Timeout task (e.g., 5 seconds)
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                throw PhotoCaptureError.timedOut
            }

            // Return the first completed result and cancel the other task.
            do {
                let result = try await group.next()!
                group.cancelAll()
                return result
            } catch {
                group.cancelAll()
                throw error
            }
        }
        #endif
    }

    // MARK: - Create a photo settings object.

    // Create a photo settings object with the features a person enables in the UI.
    private func createPhotoSettings(with features: PhotoFeatures) -> AVCapturePhotoSettings {
        // Create a new settings object to configure the photo capture.
        var photoSettings = AVCapturePhotoSettings()

        // Capture photos in HEIF format when the device supports it.
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }

        /// Set the format of the preview image to capture. The `photoSettings` object returns the available
        /// preview format types in order of compatibility with the primary image.
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }

        /// Set the largest dimensions that the photo output supports.
        /// `CaptureService` automatically updates the photo output's `maxPhotoDimensions`
        /// when the capture pipeline changes.
        photoSettings.maxPhotoDimensions = photoOutput.maxPhotoDimensions

        // Set the priority of speed versus quality during this capture.
        if let prioritization = AVCapturePhotoOutput.QualityPrioritization(rawValue: features.qualityPrioritization.rawValue) {
            photoSettings.photoQualityPrioritization = prioritization
        }

        return photoSettings
    }

    // MARK: - Update the photo output configuration

    /// Reconfigures the photo output and updates the output service's capabilities accordingly.
    ///
    /// The `CaptureService` calls this method whenever you change cameras.
    ///
    func updateConfiguration(for device: AVCaptureDevice) {
        // Enable all supported features.
        photoOutput.maxPhotoDimensions = device.activeFormat.supportedMaxPhotoDimensions.last ?? .zero
        photoOutput.maxPhotoQualityPrioritization = .quality
        photoOutput.isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureSupported
        photoOutput.isFastCapturePrioritizationEnabled = photoOutput.isFastCapturePrioritizationSupported
        photoOutput.isAutoDeferredPhotoDeliveryEnabled = photoOutput.isAutoDeferredPhotoDeliverySupported
    }
}

typealias PhotoContinuation = CheckedContinuation<Photo, Error>

// MARK: - A photo capture delegate to process the captured photo.

/// An object that adopts the `AVCapturePhotoCaptureDelegate` protocol to respond to photo capture life-cycle events.
///
/// The delegate produces a stream of events that indicate its current state of processing.
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: PhotoContinuation
    private let onFinish: (PhotoCaptureDelegate) -> Void

    private var isProxyPhoto = false
    private var photoData: Data?
    private var finished = false
    private let stateLock = NSLock()

    /// Creates a new delegate object with the checked continuation to call when processing is complete.
    init(continuation: PhotoContinuation, onFinish: @escaping (PhotoCaptureDelegate) -> Void) {
        self.continuation = continuation
        self.onFinish = onFinish
    }

    private func finishIfNeeded(_ result: Result<Photo, Error>) {
        stateLock.lock()
        if finished {
            stateLock.unlock()
            return
        }
        finished = true
        stateLock.unlock()

        switch result {
        case .success(let photo):
            continuation.resume(returning: photo)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
        onFinish(self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error = error {
            logger.debug("Error capturing deferred photo: \(error.localizedDescription)")
            // If the pipeline aborts here and won't deliver final callback, fail now.
            finishIfNeeded(.failure(error))
            return
        }
        // Capture the data for this photo.
        photoData = deferredPhotoProxy?.fileDataRepresentation()
        isProxyPhoto = true
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            logger.debug("Error processing photo: \(error.localizedDescription)")
            // If the pipeline aborts here and won't deliver final callback, fail now.
            finishIfNeeded(.failure(error))
            return
        }
        photoData = photo.fileDataRepresentation()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error {
            finishIfNeeded(.failure(error))
            return
        }
        guard let photoData else {
            finishIfNeeded(.failure(PhotoCaptureError.noPhotoData))
            return
        }
        let photo = Photo(data: photoData, isProxy: isProxyPhoto)
        finishIfNeeded(.success(photo))
    }
}
