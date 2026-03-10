import SwiftUI
import VisionKit

struct BarcodeScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerRepresentable(onScan: { barcode in
                    dismiss()
                    onScan(barcode)
                })
                .ignoresSafeArea()

                scanOverlay
            } else {
                unsupportedView
            }
        }
    }

    // MARK: - Overlay UI

    private var scanOverlay: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.45))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            // Viewfinder frame
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white, lineWidth: 2.5)
                .frame(width: 260, height: 160)
                .overlay(
                    Canvas { ctx, size in
                        let w = size.width
                        let h = size.height
                        let len: CGFloat = 24
                        let thick: CGFloat = 4
                        let r: CGFloat = 16
                        var path = Path()
                        // Top-left
                        path.move(to: CGPoint(x: r, y: 0)); path.addLine(to: CGPoint(x: r + len, y: 0))
                        path.move(to: CGPoint(x: 0, y: r)); path.addLine(to: CGPoint(x: 0, y: r + len))
                        // Top-right
                        path.move(to: CGPoint(x: w - r, y: 0)); path.addLine(to: CGPoint(x: w - r - len, y: 0))
                        path.move(to: CGPoint(x: w, y: r)); path.addLine(to: CGPoint(x: w, y: r + len))
                        // Bottom-left
                        path.move(to: CGPoint(x: r, y: h)); path.addLine(to: CGPoint(x: r + len, y: h))
                        path.move(to: CGPoint(x: 0, y: h - r)); path.addLine(to: CGPoint(x: 0, y: h - r - len))
                        // Bottom-right
                        path.move(to: CGPoint(x: w - r, y: h)); path.addLine(to: CGPoint(x: w - r - len, y: h))
                        path.move(to: CGPoint(x: w, y: h - r)); path.addLine(to: CGPoint(x: w, y: h - r - len))
                        ctx.stroke(path, with: .color(Color(hex: "667eea")), lineWidth: thick)
                    }
                )

            Spacer()

            // Bottom hint
            VStack(spacing: 6) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: "667eea"))
                Text("Point the camera at a barcode")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text("EAN, UPC, and QR codes are supported")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.bottom, 50)
        }
    }

    // MARK: - Unsupported

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Barcode scanning is not available on this device.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Close") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "667eea"))
        }
    }
}

// MARK: - UIKit wrapper

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .code39, .qr])
            ],
            qualityLevel: .balanced,
            isHighlightingEnabled: false
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var scanned = false

        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            guard !scanned else { return }
            guard case .barcode(let item) = addedItems.first,
                  let payload = item.payloadStringValue else { return }
            scanned = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onScan(payload)
        }
    }
}
