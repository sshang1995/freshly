import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ItemFormViewModel(item: nil)
    @State private var isSaving = false
    @State private var showScanner = false
    @State private var isLookingUp = false
    @State private var lookupError: String? = nil

    private let barcodeService = BarcodeProductService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ItemFormView(viewModel: viewModel)

                if isLookingUp {
                    lookupBanner(text: "Looking up product…", isError: false)
                } else if let error = lookupError {
                    lookupBanner(text: error, isError: true)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        lookupError = nil
                        showScanner = true
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "667eea"))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isSaving = true
                            await viewModel.save(context: context)
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(hex: "667eea"))
                        }
                    }
                    .disabled(!viewModel.isValid || isSaving)
                }
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { barcode in
                    Task { await handleScannedBarcode(barcode) }
                }
            }
        }
    }

    // MARK: - Barcode handling

    private func handleScannedBarcode(_ barcode: String) async {
        isLookingUp = true
        lookupError = nil
        do {
            let product = try await barcodeService.lookup(barcode: barcode)
            viewModel.apply(scannedProduct: product)
        } catch {
            lookupError = error.localizedDescription
        }
        isLookingUp = false
    }

    // MARK: - Banner

    private func lookupBanner(text: String, isError: Bool) -> some View {
        HStack(spacing: 10) {
            if !isError {
                ProgressView().tint(.white)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            if isError {
                Button {
                    lookupError = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isError ? Color(hex: "ff5e62") : Color(hex: "667eea"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: isLookingUp)
    }
}
