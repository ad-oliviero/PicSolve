# PicSolve
Simple iOS App to help you solve mathematical problems. Inspired by Photomath

# Repository Content
- [Picsolve/](./PicSolve/) and [Picsolve.xcodeproj/](./PicSolve.xcodeproj/) contain the actual code for the app
- [LICENSE](./LICENSE) contains the MIT license
- [Presentation.key](./Presentation.key) is the Keynote Presentation File

## Additional Content
- The directory [PicSolve/Pix2TextModels/](./PicSolve/Pix2TextModels/) contains the ML models used for the recognition
- The directory [PicSolve/Camera/](./PicSolve/Camera/) contains code mostly
taken from the [official AVCam example](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)

# Frameworks and technologies used for this project
- Swift & SwiftUI
- [AVCam](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app) for the camera view
- [ONNX Runtime](https://onnxruntime.ai/docs/build/ios.html) to use non-CoreML models on ios
- [Pix2Text Models](https://github.com/breezedeus/Pix2Text): [Math Formula
Detection](https://huggingface.co/breezedeus/pix2text-mfd-1.5) [Math Formula Recognition](https://huggingface.co/breezedeus/pix2text-mfr-1.5)

# Building the project
Before building, it is necessary to download the ML models:
```sh
git submodule update --init
```
After that it is possible to regularly build the project with xcode
