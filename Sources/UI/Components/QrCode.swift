import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

/// A QR code generated on-device (no data leaves the device), via CoreImage.
/// Mirrors the Android `QrCode` component.
struct QrCode: View {
    let data: String
    var size: CGFloat

    var body: some View {
        Group {
            if let image = Self.generate(data) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Color.white
            }
        }
        .frame(width: size, height: size)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private static func generate(_ text: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
