/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 A Camera implementation to use when working with SwiftUI previews.
 */

import Foundation
import os
import SwiftUI

@MainActor
@Observable
class PreviewCameraModel: Camera {
    // MARK: - Camera protocol properties
    
    private(set) var status = CameraStatus.unknown
    private(set) var captureActivity = CaptureActivity.idle
    
    var captureMode = CaptureMode.photo {
        didSet {
            Task {
                // Create a short delay to mimic the time it takes to reconfigure the session.
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
            }
        }
    }
    
    private(set) var isSwitchingVideoDevices = false
    var shouldFlashScreen: Bool = false
    
    var qualityPrioritization = QualityPrioritization.quality
    var error: Error?
    
    // PreviewSource to satisfy the protocol (no-op for previews)
    struct PreviewSourceStub: PreviewSource {
        func connect(to target: PreviewTarget) {}
    }

    let previewSource: PreviewSource = PreviewSourceStub()
    
    // MARK: - Init
    
    init(captureMode: CaptureMode = .photo, status: CameraStatus = .unknown) {
        self.captureMode = captureMode
        self.status = status
    }
    
    // MARK: - Camera protocol methods
    
    func start() async {
        if status == .unknown {
            status = .running
        }
    }
    
    func switchVideoDevices() async {
        // Simulate a brief device switch delay.
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        try? await Task.sleep(until: .now + .milliseconds(200), clock: .continuous)
        logger.debug("Device switching isn't implemented in PreviewCamera.")
    }
    
    func capturePhoto() async -> Data? {
        // Simulate a quick capture for UI feedback.
        captureActivity = .photoCapture(willCapture: true)
        shouldFlashScreen = true
        try? await Task.sleep(until: .now + .milliseconds(150), clock: .continuous)
        captureActivity = .idle
        shouldFlashScreen = false
        logger.debug("Photo capture isn't implemented in PreviewCamera.")
        return nil
    }
    
    func focusAndExpose(at point: CGPoint) async {
        logger.debug("Focus and expose isn't implemented in PreviewCamera.")
    }
}
