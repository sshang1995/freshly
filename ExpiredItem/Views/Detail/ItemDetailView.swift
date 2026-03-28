import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: Item
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                expiryCard
                detailsCard
                if let notes = item.notes, !notes.isEmpty { notesCard(notes) }
                if item.completionState == .active { actionButtons }
                if item.completionState != .active { completionCard }
                deleteButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if item.completionState == .active {
                ToolbarItem(placement: .primaryAction) {
                    Button(L("detail.edit")) { showEditSheet = true }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "667eea"))
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditItemSheet(item: item)
        }
        .confirmationDialog(String(format: L("detail.deleteDialogTitle"), item.name), isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(L("detail.delete"), role: .destructive) {
                ItemFormViewModel(item: item).delete(item: item, context: context)
                dismiss()
            }
            Button(L("detail.cancel"), role: .cancel) {}
        } message: {
            Text(L("detail.deleteConfirm"))
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(item.status.gradient)
                .frame(height: 160)

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 120, height: 120)
                .offset(x: 230, y: -20)

            Circle()
                .fill(.white.opacity(0.07))
                .frame(width: 80, height: 80)
                .offset(x: 270, y: 40)

            HStack(alignment: .bottom, spacing: 14) {
                CategoryIconView(category: item.category, size: 56)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    StatusBadgeView(status: item.status)
                }
                Spacer()
            }
            .padding(20)
        }
        .shadow(color: item.status.glowColor, radius: 12, y: 4)
    }

    // MARK: - Expiry Card
    private var expiryCard: some View {
        HStack(spacing: 0) {
            expiryColumn(title: L("detail.expires"), value: item.expirationDate.shortFormatted)
            Divider().frame(height: 40)
            expiryColumn(title: L("detail.daysLeft"), value: daysLeftText, valueColor: item.status.color)
            if let purchase = item.purchaseDate {
                Divider().frame(height: 40)
                expiryColumn(title: L("detail.purchased"), value: purchase.shortFormatted)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func expiryColumn(title: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Details Card
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(icon: item.category.icon, iconColor: item.category.color, label: L("detail.category"), value: item.category.displayName)
            Divider().padding(.leading, 52)
            detailRow(icon: item.location.icon, iconColor: Color(hex: "667eea"), label: L("detail.location"), value: item.location.displayName)
            if let qty = item.quantity, !qty.isEmpty {
                Divider().padding(.leading, 52)
                detailRow(icon: "number.circle.fill", iconColor: Color(hex: "764ba2"), label: L("detail.quantity"), value: qty)
            }
            Divider().padding(.leading, 52)
            let reminderDays = item.reminderOffsetDays
            detailRow(
                icon: "bell.fill",
                iconColor: .orange,
                label: L("detail.reminder"),
                value: Lf(reminderDays == 1 ? "detail.dayBefore" : "detail.daysBefore", reminderDays)
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func detailRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Notes Card
    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L("detail.notes"), systemImage: "note.text")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.3)
            Text(notes)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(
                label: L("detail.consumed"),
                icon: "checkmark.circle.fill",
                colors: [Color(hex: "11998e"), Color(hex: "38ef7d")]
            ) { markComplete(state: .consumed) }

            actionButton(
                label: L("detail.discard"),
                icon: "trash.circle.fill",
                colors: [Color(hex: "F7971E"), Color(hex: "FFD200")]
            ) { markComplete(state: .discarded) }
        }
    }

    private func actionButton(label: String, icon: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: colors[0].opacity(0.4), radius: 8, y: 3)
        }
        .disabled(isProcessing)
    }

    // MARK: - Completion Card
    private var completionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "667eea").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color(hex: "667eea"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.completionState.displayName)
                    .font(.system(size: 15, weight: .semibold))
                if let date = item.completionDate {
                    Text(date.shortFormatted)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Delete
    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                Text(L("detail.delete"))
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helpers
    private var daysLeftText: String {
        let days = item.daysUntilExpiration
        switch days {
        case ..<0: return Lf("detail.daysAgo", abs(days))
        case 0: return L("detail.today")
        case 1: return L("detail.tomorrow")
        default: return Lf("detail.daysLeft.format", days)
        }
    }

    private func markComplete(state: CompletionState) {
        isProcessing = true
        ItemFormViewModel(item: item).markComplete(item: item, state: state, context: context)
        isProcessing = false
    }
}

// MARK: - Edit Sheet
private struct EditItemSheet: View {
    let item: Item
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ItemFormViewModel
    @State private var isSaving = false

    init(item: Item) {
        self.item = item
        self._viewModel = State(initialValue: ItemFormViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            ItemFormView(viewModel: viewModel)
                .navigationTitle(L("editItem.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L("editItem.cancel")) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L("editItem.save")) {
                            Task {
                                isSaving = true
                                await viewModel.save(context: context)
                                isSaving = false
                                dismiss()
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "667eea"))
                        .disabled(!viewModel.isValid || isSaving)
                    }
                }
        }
    }
}
