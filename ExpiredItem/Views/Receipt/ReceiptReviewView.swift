import SwiftUI
import SwiftData

struct ReceiptReviewView: View {
    let image: UIImage

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ReceiptReviewViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isProcessing {
                    loadingView
                } else if let error = viewModel.processingError {
                    errorView(message: error)
                } else if viewModel.reviewItems.isEmpty {
                    emptyView
                } else {
                    itemList
                }
            }
            .navigationTitle(L("receipt.review.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("receipt.review.cancel")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !viewModel.reviewItems.isEmpty && !viewModel.isProcessing {
                    bottomBar
                }
            }
        }
        .task {
            await viewModel.process(image: image)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
            Text(L("receipt.review.processing"))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await viewModel.process(image: image) }
            } label: {
                Text(L("receipt.review.retry"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "667eea"))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(L("receipt.review.noItems"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Button {
                dismiss()
            } label: {
                Text(L("receipt.review.retry"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "667eea"))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Item List

    private var itemList: some View {
        List {
            ForEach($viewModel.reviewItems) { $item in
                ReviewItemRow(item: $item)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                Task {
                    await viewModel.saveAll(context: modelContext)
                    dismiss()
                }
            } label: {
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(Lf("receipt.review.addItems", viewModel.includedCount))
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.includedCount == 0
                        ? LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.includedCount == 0 || viewModel.isSaving)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Review Item Row

private struct ReviewItemRow: View {
    @Binding var item: ReceiptReviewViewModel.ReviewItem
    @State private var showCategoryPicker = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                item.isIncluded.toggle()
            } label: {
                Image(systemName: item.isIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isIncluded ? Color(hex: "667eea") : Color(.tertiaryLabel))
            }
            .buttonStyle(.plain)

            // Category icon
            Button {
                showCategoryPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(item.category.color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.category.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(item.category.color)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                TextField(L("form.field.namePlaceholder"), text: $item.name)
                    .font(.system(size: 15, weight: .semibold))

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text(L("receipt.review.quantity"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        TextField("-", text: $item.quantity)
                            .font(.system(size: 12))
                            .frame(maxWidth: 56)
                    }

                    HStack(spacing: 4) {
                        Text(L("receipt.review.expiry"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $item.expirationDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .scaleEffect(0.8, anchor: .leading)
                            .frame(height: 28)
                            .clipped()
                    }
                }
            }
        }
        .opacity(item.isIncluded ? 1 : 0.4)
        .padding(.vertical, 2)
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $item.category)
        }
    }
}

// MARK: - Category Picker Sheet

private struct CategoryPickerSheet: View {
    @Binding var selectedCategory: Category
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Category.allCases) { category in
                Button {
                    selectedCategory = category
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                            .frame(width: 28)
                        Text(category.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if category == selectedCategory {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: "667eea"))
                        }
                    }
                }
            }
            .navigationTitle(L("form.section.category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("receipt.review.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
