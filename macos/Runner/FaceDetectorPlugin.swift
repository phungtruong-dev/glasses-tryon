import FlutterMacOS
import Vision

/// Flutter plugin wrapping Apple Vision framework for face landmark detection.
/// Channel: "glasses_tryon/face_detector"
///
/// Methods:
///   detectFromBytes({bytes, width, height, bytesPerRow}) -> [[leX,leY,reX,reY,yaw], ...]
///   detectFromFile(path: String)                          -> [[leX,leY,reX,reY,yaw], ...]
///
/// Coordinates returned are in pixel space with top-left origin (Flutter convention).
class FaceDetectorPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "glasses_tryon/face_detector",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(FaceDetectorPlugin(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "detectFromBytes":
            guard let args = call.arguments as? [String: Any],
                  let typedData = args["bytes"] as? FlutterStandardTypedData,
                  let width = args["width"] as? Int,
                  let height = args["height"] as? Int,
                  let bytesPerRow = args["bytesPerRow"] as? Int else {
                result([])
                return
            }
            detectFromBytes(
                typedData.data, width: width, height: height,
                bytesPerRow: bytesPerRow, result: result
            )

        case "detectFromFile":
            guard let path = call.arguments as? String else { result([]); return }
            detectFromFile(path: path, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Private

    /// Raw ARGB bytes from camera_macos (NSBitmapImageRep.bitmapData format:
    /// premultipliedFirst | byteOrder32Big → A,R,G,B per pixel).
    private func detectFromBytes(
        _ data: Data, width: Int, height: Int,
        bytesPerRow: Int, result: @escaping FlutterResult
    ) {
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue |
            CGBitmapInfo.byteOrder32Big.rawValue
        )
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                width: width, height: height,
                bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil, shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            result([])
            return
        }
        runVision(on: CIImage(cgImage: cgImage),
                  imageW: Double(width), imageH: Double(height), result: result)
    }

    private func detectFromFile(path: String, result: @escaping FlutterResult) {
        guard let ciImage = CIImage(contentsOf: URL(fileURLWithPath: path)) else {
            result([])
            return
        }
        let ext = ciImage.extent
        runVision(on: ciImage, imageW: Double(ext.width), imageH: Double(ext.height), result: result)
    }

    /// Core Vision request. Returns [[leX, leY, reX, reY, yaw], ...] on the main thread.
    private func runVision(
        on ciImage: CIImage, imageW: Double, imageH: Double,
        result: @escaping FlutterResult
    ) {
        let request = VNDetectFaceLandmarksRequest { req, err in
            guard err == nil else { DispatchQueue.main.async { result([]) }; return }
            let faces = req.results as? [VNFaceObservation] ?? []

            let mapped: [[Double]] = faces.compactMap { face in
                guard let lm = face.landmarks,
                      let leRegion = lm.leftEye,
                      let reRegion = lm.rightEye,
                      !leRegion.normalizedPoints.isEmpty,
                      !reRegion.normalizedPoints.isEmpty else { return nil }

                let bb = face.boundingBox

                // Average all contour points for a stable eye centre.
                func centre(_ region: VNFaceLandmarkRegion2D) -> CGPoint {
                    let n = CGFloat(region.normalizedPoints.count)
                    return region.normalizedPoints.reduce(.zero) {
                        CGPoint(x: $0.x + $1.x / n, y: $0.y + $1.y / n)
                    }
                }

                let lc = centre(leRegion)
                let rc = centre(reRegion)

                // Landmark points are in face-bounding-box space (bottom-left origin).
                // Convert to image-normalised space, then flip Y for Flutter (top-left).
                func toPixel(_ p: CGPoint) -> (Double, Double) {
                    let absX = bb.minX + p.x * bb.width
                    let absY = bb.minY + p.y * bb.height
                    return (absX * imageW, (1.0 - absY) * imageH)
                }

                let (leX, leY) = toPixel(lc)
                let (reX, reY) = toPixel(rc)
                // Convert Vision radians → degrees to match MLKit convention used by drawGlassesAtEyes.
                let toDeg = 180.0 / Double.pi
                let yawDeg = (face.yaw?.doubleValue ?? 0.0) * toDeg
                // pitch is only available on macOS 12+; fall back to 0 on older systems.
                let pitchDeg: Double
                if #available(macOS 12.0, *) {
                    pitchDeg = (face.pitch?.doubleValue ?? 0.0) * toDeg
                } else {
                    pitchDeg = 0.0
                }

                return [leX, leY, reX, reY, yawDeg, pitchDeg]
            }

            DispatchQueue.main.async { result(mapped) }
        }

        DispatchQueue.global(qos: .userInteractive).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([request])
        }
    }
}
