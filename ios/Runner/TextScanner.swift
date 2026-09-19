import Flutter
import PDFKit
import UIKit
import Vision

/// On-device text recognition for scanned matric results.
///
/// Uses Apple's Vision framework rather than a third-party OCR package. Vision
/// ships with iOS, so there is no extra dependency for a government codebase to
/// keep patched, it runs entirely on the device with no network call, and
/// unlike ML Kit it builds for the simulator as well as hardware.
///
/// A PDF is rasterised with PDFKit and then put through the same recogniser, so
/// a photograph of a results slip and a downloaded statement follow one path.
enum TextScanner {
  static let channelName = "khetha.dhet/text_scanner"

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "TextScanner")?.messenger()
    else { return }

    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "recognise":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String
        else {
          result(FlutterError(code: "bad_args",
                              message: "A file path is required.",
                              details: nil))
          return
        }
        // Recognition is CPU-bound; keeping it off the main thread stops the
        // UI freezing on a large scan.
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let payload = try recognise(path: path)
            DispatchQueue.main.async { result(payload) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "scan_failed",
                                  message: error.localizedDescription,
                                  details: nil))
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private enum ScanError: LocalizedError {
    case unreadableFile
    case emptyDocument

    var errorDescription: String? {
      switch self {
      case .unreadableFile:
        return "That file could not be opened as an image or a PDF."
      case .emptyDocument:
        return "That PDF has no pages."
      }
    }
  }

  private static func recognise(path: String) throws -> [String: Any] {
    let image = try loadImage(path: path)
    guard let cgImage = image.cgImage else { throw ScanError.unreadableFile }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    // Results statements carry subject names, codes and percentages rather than
    // prose, so the language model would fight the input more than help it.
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["en-ZA", "en-US"]

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try handler.perform([request])

    let observations = request.results ?? []

    // Vision returns each cell of a table as its own observation, in no
    // dependable order. A results statement IS a table, so the observations are
    // grouped back into rows by vertical overlap and then sorted left to right.
    // Without this, "ACCOUNTING", "72" and "6" arrive as three unrelated lines,
    // sometimes with the number ahead of the subject, and no amount of parsing
    // on the Dart side can reliably put them back together.
    struct Fragment {
      let text: String
      let confidence: Double
      let minX: CGFloat
      let midY: CGFloat
      let height: CGFloat
    }

    var fragments: [Fragment] = []
    for observation in observations {
      guard let candidate = observation.topCandidates(1).first else { continue }
      let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
      if text.isEmpty { continue }
      let box = observation.boundingBox
      fragments.append(Fragment(
        text: text,
        confidence: Double(candidate.confidence),
        minX: box.minX,
        midY: box.midY,
        height: box.height
      ))
    }

    // Vision's origin is bottom-left, so a larger midY is further up the page.
    fragments.sort { $0.midY > $1.midY }

    var rows: [[Fragment]] = []
    for fragment in fragments {
      if let last = rows.last, let reference = last.first {
        // Same row when the vertical centres are within a fraction of the taller
        // fragment's height. Generous enough for a slightly rotated photograph,
        // tight enough not to merge adjacent rows of a dense table.
        let tolerance = max(reference.height, fragment.height) * 0.6
        if abs(reference.midY - fragment.midY) <= tolerance {
          rows[rows.count - 1].append(fragment)
          continue
        }
      }
      rows.append([fragment])
    }

    var lines: [String] = []
    var confidences: [Double] = []

    for row in rows {
      let ordered = row.sorted { $0.minX < $1.minX }
      // Two spaces, so the Dart parser can still tell columns apart if it needs
      // to while a single-space join would read as prose.
      lines.append(ordered.map(\.text).joined(separator: "  "))
      confidences.append(contentsOf: ordered.map(\.confidence))
    }

    let average = confidences.isEmpty
      ? 0
      : confidences.reduce(0, +) / Double(confidences.count)

    return [
      "lines": lines,
      "confidence": average,
      "engine": "Apple Vision (on-device)",
    ]
  }

  private static func loadImage(path: String) throws -> UIImage {
    let url = URL(fileURLWithPath: path)

    if url.pathExtension.lowercased() == "pdf" {
      guard let document = PDFDocument(url: url) else { throw ScanError.unreadableFile }
      guard let page = document.page(at: 0) else { throw ScanError.emptyDocument }

      let bounds = page.bounds(for: .mediaBox)
      // Render at 2x so small print survives rasterisation.
      let scale: CGFloat = 2
      let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)

      let renderer = UIGraphicsImageRenderer(size: size)
      return renderer.image { context in
        UIColor.white.set()
        context.fill(CGRect(origin: .zero, size: size))
        context.cgContext.translateBy(x: 0, y: size.height)
        context.cgContext.scaleBy(x: scale, y: -scale)
        page.draw(with: .mediaBox, to: context.cgContext)
      }
    }

    guard let image = UIImage(contentsOfFile: path) else { throw ScanError.unreadableFile }
    return image
  }
}
